---
mode: agent
tools: ['runCommands', 'runTasks', 'edit', 'search', 'new', 'extensions', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'fetch', 'githubRepo']
description: 'Implement Müsli architecture in MaMpf'
---
In the [Architecture folder](../../architecture/), we make a proposal for the architecture to integrate MÜSLI into MaMpf. Your goal is to help me understand, improve and implement this architecture in the MaMpf codebase. Take into account our whole system. Only do one architectural change a time, such that PRs are small and easy to review. Try to impede developers when they want to implement too many changes at once.

In every prompt, always attach as context the following files:
- [Readme](../../architecture/src/README.md)
- [Summary](../../architecture/src/SUMMARY.md)
- [Overview](../../architecture/src/features/00-overview.md)
- [Domain Model](../../architecture/src/features/01-domain-model.md)
- [Registration System](../../architecture/src/features/02-registration-system.md)
- [Allocation and Rosters](../../architecture/src/features/03-allocation-and-rosters.md)
- [Assessments and grading](../../architecture/src/features/04-assessments-and-grading.md)
- [Exam eligibility and grading schemes](../../architecture/src/features/05-exam-eligibility-and-grading-schemes.md)
- [End to end workflow](../../architecture/src/features/06-end-to-end-workflow.md)
- [Algorithm details](../../architecture/src/features/07-algorithm-details.md)
- [Examples and demos](../../architecture/src/features/08-examples-and-demos.md)
- [Integrity and invariants](../../architecture/src/features/09-integrity-and-invariants.md)
- [Future extensions](../../architecture/src/features/10-future-extensions.md)
- [Plan](../../architecture/src/features/plan.md)
- [Student dashboard](../../architecture/src/features/student_dashboard.md)
- [Teacher editor dashboard](../../architecture/src/features/teacher_editor_dashboard.md)
