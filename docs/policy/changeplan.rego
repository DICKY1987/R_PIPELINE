package changeplan

default allow = false

allow {
  input.changeplan.id
  input.changeplan.summary
  count(input.changeplan.steps) > 0
  input.changeplan.riskAssessment.level != "high"
}

violation[msg] {
  not allow
  msg := "ChangePlan must include id, summary, steps, and risk level below high."
}
