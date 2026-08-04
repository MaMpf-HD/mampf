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
export async function createAssessedAssignment(
  factory: FactoryBot,
  teacherId: number,
  title = "Problem Set 1",
): Promise<AssessedAssignment> {
  const lecture = await factory.create("lecture", ["released_for_all"], {
    teacher_id: teacherId,
    locale: "en",
  });
  const assignment = await factory.create("assignment", [], {
    lecture_id: lecture.id,
    title,
  });
  const assessment = await assignment.__call("assessment");

  return { lecture, assignment, assessmentId: assessment.id };
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
