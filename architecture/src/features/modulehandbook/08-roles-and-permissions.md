# Roles & Permissions

- The handbook is official: only the admin may change structure, content or status.
- Viewers must never see unreviewed content, including through export parameters.

## Solution Architecture
- **Admin = existing MaMpf admin flag** for the first version; no new role column until a third role exists.

## Future: Lecturer Role

| Capability | Rule |
|------------|------|
| Edit content | Only editions where the lecturer is `responsible` |
| Change status | Never; edits reset to `created` and wait for admin review |
| Structure | No access to handbooks, sections, entries |

Requires `responsible` to become a user reference (`responsible_user_id`) instead of free text. See [Future Extensions](10-future-extensions.md#lecturer-role).
