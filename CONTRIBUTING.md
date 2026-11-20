# Contributing

Thanks for helping. This is an experimental, design-phase project: nothing has been built or ridden yet. Bench results, build reports and design reviews are as useful as code.

## Before you start

- Read the relevant part of [`docs/design.md`](docs/design.md) (hardware) or [`docs/firmware-spec.md`](docs/firmware-spec.md) (firmware). They are the source of truth.
- Check [`docs/build-plan.md`](docs/build-plan.md). Work goes phase by phase, so changes for a later phase may wait.
- For anything bigger than a fix, open an issue first so we can agree on the approach.

## Firm constraints

These are the owner's decisions. A change that breaks one won't be merged without the owner's agreement:

- Only the mirror moves. The LEDs and heatsink stay fixed.
- External power only. The head has no battery.
- Material cost ≤ $450 per unit and head weight ≤ 350 g, both with the optional lidar fitted.
- The lidar stays optional. Everything must work without it.

## Making a change

1. Branch from `main`. One branch and one pull request per change.
2. Update the docs in the same pull request as the change:
   - behaviour → `docs/design.md` or `docs/firmware-spec.md`
   - parts → `hardware/BOM.md`, `hardware/BOM.csv` and the cost summary, together, then check the cost and weight limits
   - a line in `CHANGELOG.md` under Unreleased
3. Tests come with the change. Each test has an ID in [`docs/test-plan.md`](docs/test-plan.md):
   - Automated firmware tests are named after their ID, for example `test_U_FILT_02_braking_does_not_tilt`. Add the row to the test plan.
   - Keep firmware logic in modules with no hardware I/O, and pass the time and sensor readings in, so it runs on a computer with `pio test -e native`.
   - A bug fix's test must fail without the fix.
4. For bench, enclosure or ride results, fill in the test's Status with the date, the result and your setup. Photos and logs in the pull request help.
5. Sign your commits.

## Safety

Never weaken the safety invariants in [`firmware-spec.md` §1](docs/firmware-spec.md#1-safety-invariants-always-true). The beam must never go fully off while moving, and the lidar must never raise the beam. Ride-test changes only after the bench tests pass, and always with a backup light.

## Privacy

Don't put personal data in the repository: no real names, locations, accounts or hostnames in code, docs, test data or commit messages. Keep personal build or ride notes in `*.local.md` files, which git ignores.

## Licence

By contributing, you agree that your contribution is licensed under the project's [GPL-3.0 licence](LICENSE).
