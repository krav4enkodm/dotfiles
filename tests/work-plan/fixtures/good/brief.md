# Brief: team members page

Goal: team admins see who is in a team and invite people by email.

## Rules and examples
- **R1** The API returns a team's members, newest first.
  - **E1** Given a team with 3 members, when the list is requested, then all 3 come back newest first.
- **R2** Only admins see the invite button.
  - **E2** Given a viewer who isn't an admin, when the page loads, then there is no invite button.
- **R3** Inviting adds a pending member to the list.
  - **E3** Given a valid email, when the invite is sent, then the list shows the new member as pending.

## Data map
| Element | Data | Source | Status |
|---|---|---|---|
| U1 | team.name, team.memberCount | GET /teams/:id | exists |
| U2 | member.name, member.role | GET /teams/:id/members | new |
