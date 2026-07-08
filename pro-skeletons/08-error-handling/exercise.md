# Pro Module 8: Error Handling

## Objective
Learn to handle errors gracefully in playbooks using block/rescue, assert, and proper failure conditions.

## Starter
See the lab's playbooks/60_error_handling.yml for examples.

## Tasks for learner
1. Create a role that installs a package and falls back on error.
2. Use assert to validate facts.
3. Add wait_for for service readiness.

## Check
Run the check in checks/ or your own.

See official docs:
- https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_blocks.html
- https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/assert_module.html
