# AI_RUBRIC (10 checks)

1 Correctness & edge cases
2 Types (or parameter validation)
3 Error handling (no broad catches)
4 Idempotence (when applicable)
5 ShouldProcess / -WhatIf (PS side-effects)
6 Logging (structured; no print)
7 Security (no secrets/eval/shell True)
8 Style (matches STYLEGUIDE)
9 Tests quality (fail first → pass)
10 Diff size & focus

Return: PASS/FAIL per item. If any FAIL → fix → re-run.

