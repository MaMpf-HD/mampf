# ADR 0001: Strict Superset Model for User-Facing Type Labels

## Status

Accepted

## Context

The registration system supports multiple registerable types: `Tutorial`, `Talk`, and `Cohort`. However, `Cohort` serves three distinct purposes:
- **Enrollment Groups** (`purpose: :enrollment`) - for simple courses without tutorials
- **Planning Surveys** (`purpose: :planning`) - for demand forecasting
- **Other Groups** (`purpose: :general`) - for flexible groupings (waitlists, special groups, etc.)

We needed to decide how to present these types to users in the UI and how to handle them in the backend.

## Decision

We implement a **Strict Superset Model**: the UI exposes user-facing labels that are a strict superset of the underlying model classes.

### Type Mapping

**User-Facing Labels → Model Classes:**
```ruby
"Tutorial"         → Tutorial
"Talk"             → Talk
"Enrollment Group" → Cohort (purpose: :enrollment)
"Planning Survey"  → Cohort (purpose: :planning)
"Other Group"      → Cohort (purpose: :general)
```

### Key Principles

1. **User-facing labels everywhere**: Forms, dropdowns, help text, and display use semantic labels ("Enrollment Group"), never technical terms ("Cohort").

2. **Controller as translation layer**: `ItemsController` maintains the `REGISTERABLE_CLASSES` mapping and translates user-facing labels to model classes and cohort purposes.

3. **Model knows nothing about UI labels**: The `Cohort` model only knows about `purpose` enum values. It doesn't contain UI strings.

4. **One source of truth per layer**:
   - **Controller**: `REGISTERABLE_CLASSES` and `COHORT_TYPE_TO_PURPOSE` constants
   - **Service**: `AvailableItemsService#creatable_types` returns UI labels
   - **Frontend**: Stimulus controllers use the same UI labels
   - **Locales**: I18n keys reference the UI labels

## Rationale

### Why Not Expose "Cohort" in the UI?

**Problem**: Users don't care about the technical implementation detail that enrollment groups and planning surveys are both cohorts. Exposing "Cohort" would:
- Require users to understand an abstraction that doesn't match their mental model
- Need additional UI to select cohort purpose (extra cognitive load)
- Conflate conceptually different things under one label

**Solution**: Present each use case as a distinct type at the UI level, even though they share implementation.

### Why Not Create Separate Models?

**Problem**: Creating `EnrollmentGroup`, `PlanningSurvey`, and `OtherGroup` as separate models would:
- Introduce code duplication for shared behavior
- Require multiple join tables for polymorphic associations
- Complicate queries across all group types
- Make it harder to add new cohort purposes in the future

**Solution**: Single `Cohort` model with `purpose` enum provides implementation flexibility while the UI layer provides clarity.

### Benefits

1. **Clear user experience**: Users see meaningful labels that match their intent
2. **Flexible implementation**: Backend can refactor without UI changes
3. **Type safety**: Controller validates allowed types at entry point
4. **Future-proof**: New cohort purposes can be added by extending the mapping
5. **Separation of concerns**: UI layer concerns stay in UI, domain logic stays in models

### Trade-offs

**Accepted complexity**:
- Type mapping logic in controller (manageable, well-documented)
- Multiple labels pointing to same model (clear from constants)
- Display logic must check cohort purpose (handled in helper)

**Rejected alternatives**:
- ❌ Expose "Cohort" + purpose selection (bad UX)
- ❌ Create separate models (code duplication)
- ❌ Single "Group" label for all cohorts (loses semantic clarity)

## Implementation Notes

### Adding New Cohort Purposes

To add a new cohort purpose (e.g., "Audit Group"):

1. Add enum value to `Cohort` model: `purpose: [:general, :enrollment, :planning, :audit]`
2. Add mapping in `ItemsController`:
   ```ruby
   "Audit Group" => Cohort  # in REGISTERABLE_CLASSES
   "Audit Group" => :audit  # in COHORT_TYPE_TO_PURPOSE
   ```
3. Add to `AvailableItemsService#creatable_types`: `types << "Audit Group"`
4. Add locale keys for display
5. Update Stimulus controllers if different behavior needed

### Validation Strategy

We do **not** validate `registerable_type` at the model level because:
- Controller enforces valid types at entry point (defensive programming at boundary)
- Model shouldn't know about UI presentation layer
- Adding validation would couple model to UI concerns

Defense-in-depth is achieved through:
- Controller type mapping (primary)
- UI not exposing invalid options (secondary)
- Tests verifying correct behavior (verification)

## Consequences

### Positive

- Users have clear, task-oriented options in the UI
- Backend can evolve independently of UI presentation
- Adding new cohort purposes is straightforward
- Type safety maintained at controller boundary

### Negative

- New developers must understand the mapping layer
- Grep for "Cohort" won't find all UI references
- Helper methods must handle cohort purpose branching

### Neutral

- Type labels defined in multiple places (controller, service, stimulus)
- Each location serves a specific purpose and documents its contract

## References

- `app/controllers/registration/items_controller.rb` - Type mapping constants
- `app/models/registration/available_items_service.rb` - Available types service
- `app/helpers/registration/items_helper.rb#item_display_type` - Display logic
- `app/frontend/registration/cohort_purpose.controller.js` - Frontend type handling
