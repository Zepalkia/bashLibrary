import logging
import re
from coalib.bears.LocalBear import LocalBear
from coalib.results.Result import Result
from coalib.results.RESULT_SEVERITY import RESULT_SEVERITY
from coalib.results.SourcePosition import SourcePosition
from coalib.results.SourceRange import SourceRange

class SyntaxBear(LocalBear):
    LANGUAGES = {"BASH"}
    def run(self, filename, file):
        n = 1
        with open(filename) as fp:
            line = fp.readline();
            while line:
                print("BOUH")
                if len(line) > 160:
                    #INFO, MAJOR
                    yield Result(self,
                            "Line should not exceed 160 chars",
                            affected_code=(SourceRange(SourcePosition(filename, n, 0)),),
                            severity=RESULT_SEVERITY.INFO,
                            confidence=100)
                if line == "false":
                    yield Result(self,
                            "Empty condition have to be fixed as soon as possible",
                            affected_code=(SourceRance(SourcePosition(filename, n, 0)),),
                            severity=RESULT_SEVERITY.MAJOR,
                            confidence=100)
                line = fp.readline()
                n += 1
