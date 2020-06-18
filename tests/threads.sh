source ../bashLibrary.sh

threads_create thr0 << THREAD
while [[ \$running == true ]]; do
  sleep 5
done
THREAD
threads_create thr1 << THREAD
while [[ \$running == true ]]; do
  sleep 3
done
THREAD
threads_create thr2 << THREAD
sleep 1
THREAD
testing_testCase "Multithreading" << TEST
assertSuccess threads_run $thr0
assertSuccess threads_run $thr1
assertSuccess threads_isRunning $thr0
assertFailure threads_isRunning $thr2
assertSuccess threads_kill $thr0
assertSuccess threads_join $thr0
assertFailure threads_isRunning $thr0
assertFailure threads_tryJoin $thr1 2
assertSuccess threads_kill $thr1
assertSuccess threads_join $thr1
assertSuccess threads_run $thr2
assertSuccess threads_delete $thr0
assertSuccess threads_delete $thr1
assertSuccess threads_join $thr2
assertSuccess threads_delete $thr2
assertFailure threads_run $thr0
TEST
