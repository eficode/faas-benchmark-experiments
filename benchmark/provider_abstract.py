# import Abstract Base Class module
# to add abstract class functionality
from abc import ABC, abstractmethod
import multiprocessing as mp
import threading as th
from functools import reduce
from concurrent import futures
import time
from datetime import datetime
from pprint import pprint


class AbstractProvider(ABC):

    @abstractmethod
    def invoke_function(self, name: str, sleep=0.0, invoke_nested: list = None):
        pass


#   ____
#  / ___|___  _ __   ___ _   _ _ __ _ __ ___ _ __   ___ _   _
# | |   / _ \| '_ \ / __| | | | '__| '__/ _ \ '_ \ / __| | | |
# | |__| (_) | | | | (__| |_| | |  | | |  __/ | | | (__| |_| |
#  \____\___/|_| |_|\___|\__,_|_|  |_|  \___|_| |_|\___|\__, |
#                                                       |___/


# auxiliary method for running X number of threads on a core/cpu


    def delegate_to_core(self, invo_args,
                         th_count: int,
                         numb_threads: int,
                         total_numb_threads: int,
                         process_barrier: mp.Barrier,
                         pipe: mp.Pipe) -> list:

        # results to be returned
        responses = []
        # threads to be build in advance to ensure all are executed at the same time
        threads = []
        # list of expetions to be logged sequentialy at the end, if any
        exceptions = []
        # lock for protection against race  conditions
        lock = th.Lock()

        try:
            # threading.barrier for ensuring execution is done simultaneously
            barrier = th.Barrier(numb_threads)
            # ThreadPoolExecutor for executing threads and getting futures in each process
            executor = futures.ThreadPoolExecutor(max_workers=numb_threads)

            # wrapper with barrier is needed to ensure all threads are executed simultaneously
            def thread_wrapper(th_id):
                # wait for all threads to have been started
                barrier.wait()
                try:
                    # call cloud function
                    future = executor.submit(
                        self.invoke_function, invo_args[0], invo_args[1], invo_args[2])
                    result = future.result()
                    for identifier in result.keys():
                        if(identifier != 'root_identifier'):
                            result[identifier]['thread_id'] = th_id
                            result[identifier]['numb_threads'] = total_numb_threads

                    with lock:
                        # append tuble of thread id and result to responses
                        responses.append(result)
                    # wait for all threads to have delivered responses
                    barrier.wait()
                except Exception as te:
                    # collect exception for later print to log
                    with lock:
                        exceptions.append(('caught exception in thread_wrapper', datetime.now(
                        ), te, f'one of {th_count}-{th_count+numb_threads-1}'))

            # build threads and append to threads list
            for i in range(numb_threads):
                threads.append(
                    th.Thread(target=thread_wrapper, args=[(th_count+i)]))

            # wait for all proccesses to have build threads
            process_barrier.wait()

            # execute threads
            for t in threads:
                t.start()
            # join threads, hence all results will have been appended to responses
            for x in threads:
                t.join()

            # return agregated responses
            pipe.send((responses, exceptions))
            pipe.close()

        except Exception as e:
            # atempt to send whatever computed results back to main process + exception
            exceptions.append(('caught exception in delegate_to_core', datetime.now(
            ), e, f'one of {th_count}-{th_count+numb_threads-1}'))
            try:
                pipe.send((responses, exceptions))
                pipe.close()
            except Exception as ex:
                # super edge-case that pipe.send() or pipe.close() throws and exception! if so, we print to log.
                # exception here might cause main process to deadlock as it will wait for process running on same core
                self.print_error('caught exception in delegate_to_core', datetime.now(
                ), e, invo_args, f'on of {th_count}-{th_count+numb_threads-1}', total_numb_threads)

    # method for orchastrating threads to processes/cpu's and returning results
    # TODO refactor to include throughput
    def invoke_function_conccrently(self, name: str,
                                    sleep=0.0,
                                    invoke_nested=None,
                                    throughput_time=0.0,
                                    numb_threads:int=1) -> list:

        thread_args = (name, sleep, invoke_nested, throughput_time)
        # find number of cpus that work can be delegated to
        system_cores = mp.cpu_count()
        # find number of threads to assign to each core
        threads_per_core = int(numb_threads / system_cores)
        # find remaining threads if perfect distribution cant be done
        remaining_threads = numb_threads % system_cores

        # data recieved from processes
        data_list = []
        # if any exceptions from processes they are agregated on main thread to be
        # printed to log sequantialy
        exception_list = []

        try:

            # barrier to inforce excution is done simultaneously at process level
            mp_barrier = mp.Barrier(system_cores)
            # list of processes to run
            processes = []
            # pipes to recieve return data from (futures)
            recieve_pipes = []

            # distribute threads to proccesses
            id_count = 1
            for i in range(system_cores):
                # number of threads given to the process
                t_numb = threads_per_core
                id_start = id_count
                # pipes to send computed data back
                recieve_pipe, send_pipe = mp.Pipe(False)
                # if threads can be distributed evenly add remaining to first process
                if(remaining_threads != 0 and i == 0):
                    t_numb += remaining_threads
                    id_count += remaining_threads
                # args for concurrent wrapper method
                process_args = (thread_args, id_start,
                                t_numb, numb_threads, mp_barrier, send_pipe)
                # create and add process to list
                processes.append(mp.Process(
                    target=self.delegate_to_core, args=process_args))
                # pup pipe in list to later retrive results
                recieve_pipes.append(recieve_pipe)
                # adjust count to give each core/cpu right load and thread id's
                id_count += threads_per_core

            # run processes concurrently
            for p in processes:
                p.start()

            # join processes
            for p in processes:
                p.join()
            time.sleep(3)

            # computation is parallelized but recieveing computed results is sequential
            for x in recieve_pipes:
                try:
                    data = x.recv()
                    data_list.append(data[0])
                    exception_list.append(data[1])
                    x.close()
                except Exception as eof:
                    exception_list.append(
                        [('caught exception while recieving from pipe', datetime.now(), eof, 'main')])

            # flatten list of lists
            flatten_data_list = reduce(lambda x, y: x+y, data_list)
            flatten_exception_list = reduce(lambda x, y: x+y, exception_list)
            # print all exception, if any, to log
            for e in flatten_exception_list:
                self.print_error(e[0], e[1], e[2],
                                 thread_args, e[3], numb_threads)

            return flatten_data_list

        except Exception as e:
            self.print_error('caught exception in invoke_function_conccrently', datetime.now(
            ), e, thread_args, 'main', numb_threads)
            return reduce(lambda x, y: x+y, data_list)

    def print_error(self, desc: str, time, exception: Exception, args, numb_threads: str, total_numb: int) -> None:
        print(desc)
        print(time)
        print('type: ' + str(type(exception)))
        print('message: ', str(exception))
        print('arguments', args)
        print(
            f'caught in {numb_threads} thread(s), out of {total_numb} threads')
        print('-----------------------------------------------------------------')
