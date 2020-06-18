source ../bashLibrary0.0.1.sh

logging_startTrace
testing_testCase "Global locking" << TEST
assertSuccess lockable_globalLock
assertFailure lockable_globalTryLock 2
assertSuccess lockable_globalUnlock
assertExit lockable_globalTryLock 1
assertSuccess lockable_globalTryLock 2
assertFailure lockable_globalTryLock 2
assertSuccess lockable_globalUnlock
assertSuccess lockable_globalUnlock
assertExit lockable_globalTryLock 1 too many arguments
TEST

testing_testCase "Name locking" << TEST
assertSuccess lockable_namedLock mylock
assertFailure lockable_namedTryLock mylock 2
assertSuccess lockable_namedUnlock mylock
assertSuccess lockable_namedTryLock mylock 2
assertFailure lockable_namedTryLock mylock 2
assertSuccess lockable_namedUnlock mylock
assertSuccess lockable_namedUnlock mylock
assertExit lockable_namedLock 1
assertExit lockable_namedTryLock 1
assertExit lockable_namedLock 1 too many arguments
assertExit lockable_namedTryLock 1 too many arguments
TEST
