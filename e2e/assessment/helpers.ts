import { FactoryBot, FactoryBotObject } from "../_support/factorybot";

type AssessedAssignment = {
  lecture: FactoryBotObject;
  assignment: FactoryBotObject;
  assessmentId: number;
};

/**
 * Creates an assignment the given teacher may edit, together with the
 * assessment the model creates for it. The feature flag has to be on before
 * this runs — the assessment is built in an `after_create` hook that checks it.
 */
export async function createLecture(
  factory: FactoryBot,
  teacherId: number,
): Promise<FactoryBotObject> {
  return factory.create("lecture", ["released_for_all"], {
    teacher_id: teacherId,
    locale: "en",
  });
}

/** Exam eligibility is what puts the certification tab on the page at all. */
export async function createEligibilityLecture(
  factory: FactoryBot,
  teacherId: number,
): Promise<FactoryBotObject> {
  return factory.create("lecture", ["released_for_all"], {
    teacher_id: teacherId,
    locale: "en",
    uses_exam_eligibility: true,
  });
}

export async function createAssessedAssignment(
  factory: FactoryBot,
  teacherId: number,
  title = "Problem Set 1",
  traits: string[] = [],
): Promise<AssessedAssignment> {
  const lecture = await factory.create("lecture", ["released_for_all"], {
    teacher_id: teacherId,
    locale: "en",
  });
  const assignment = await factory.create("assignment", traits, {
    lecture_id: lecture.id,
    title,
  });
  const assessment = await assignment.__call("assessment");

  return { lecture, assignment, assessmentId: assessment.id };
}

/**
 * Creates an assignment without an assessment — what the old system left behind.
 * The feature flag has to be off while this runs.
 */
export async function createLegacyAssignment(
  factory: FactoryBot,
  teacherId: number,
  title: string,
): Promise<{ lecture: FactoryBotObject; assignment: FactoryBotObject }> {
  const lecture = await factory.create("lecture", ["released_for_all"], {
    teacher_id: teacherId,
    locale: "en",
  });
  const assignment = await factory.create("assignment", [], {
    lecture_id: lecture.id,
    title,
  });

  return { lecture, assignment };
}

/**
 * Marks somebody, which is what makes an assignment undeletable. Only possible
 * once the deadline has passed, so the assignment has to be `expired`.
 */
export async function markSomebody(
  factory: FactoryBot,
  assessmentId: number,
): Promise<FactoryBotObject> {
  return factory.create("assessment_participation", [], {
    assessment_id: assessmentId,
    status: "reviewed",
    submitted_at: new Date().toISOString(),
  });
}

export async function scoreTask(
  factory: FactoryBot,
  taskId: number,
  participationId: number,
  points: number,
): Promise<FactoryBotObject> {
  return factory.create("assessment_task_point", [], {
    task_id: taskId,
    assessment_participation_id: participationId,
    points,
  });
}

export async function addTask(
  factory: FactoryBot,
  assessmentId: number,
  description: string,
  maxPoints: number,
): Promise<FactoryBotObject> {
  return factory.create("assessment_task", [], {
    assessment_id: assessmentId,
    description,
    max_points: maxPoints,
  });
}
