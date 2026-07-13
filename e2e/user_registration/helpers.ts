import { FactoryBot, FactoryBotObject } from "../_support/factorybot";

export async function createReleasedLecture(
  factory: FactoryBot,
  title = "Advanced Calculus",
): Promise<FactoryBotObject> {
  const course = await factory.create("course", [], { title });
  return factory.create("lecture", ["released_for_all"], { course_id: course.id });
}

export async function subscribeToLecture(
  factory: FactoryBot,
  lecture: FactoryBotObject,
  userId: number,
): Promise<void> {
  await factory.create("lecture_user_join", [], {
    lecture_id: lecture.id,
    user_id: userId,
  });
}

export async function createTutorialItemsCampaign(
  factory: FactoryBot,
  lecture: FactoryBotObject,
  allocationMode: "first_come_first_served" | "preference_based",
  description: string,
  status: "open" | "closed" = "open",
  itemsCount = 3,
  extraTraits: string[] = [],
  extraArgs: Record<string, unknown> = {},
): Promise<{ campaign: FactoryBotObject }> {
  const campaign = await factory.create(
    "registration_campaign",
    [status, allocationMode, ...extraTraits],
    {
      allocation_mode: allocationMode,
      campaignable_type: "Lecture",
      campaignable_id: lecture.id,
      description,
      items_count: itemsCount,
      ...extraArgs,
    },
  );

  return { campaign };
}
