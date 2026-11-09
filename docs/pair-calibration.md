# Pair calibration

Guided review of movie scores on the retained Stats calibration route. Delivery evidence belongs to
[validation records](reviews/delivery-validation.md#093--pair-calibration-and-daily-rotation);
storage and transport contracts remain in the linked technical references.

## Workflow

The calibration route supports comparisons once at least two live movie
ratings exist. The restored statistics page currently has no calibration entry. Series, seasons and episodes do not enter this workflow. The
screen shows two saved movie snapshots and why the pair was selected. The
explanation of the overall algorithm is expandable; no catalog request is
needed to select or answer a pair. Posters use the ordinary image cache.

Choose the first movie, the second movie or **Enjoyed both equally**. Existing
scores appear only after that choice. **Skip / I do not remember** is separate
from equality and excludes the pair for the current visit without saving an
answer. An unsaved choice can be changed.

If the answer agrees with the numeric order, save it and continue. Otherwise,
explicit correction options can raise/lower one score or adjust both. Equality
with unequal scores offers bringing either movie to the other's score. Keeping
the existing scores still records the stated preference. Merely choosing a
preference does not save an event or rewrite ratings; the subsequent action
confirms completion. Failed saves retain the choice on screen for retry.
Failed pair preparation shows a load error and Retry instead of claiming that
no pairs remain. A valid displayed pair adopts refreshed local title/poster
snapshots without discarding its unsaved answer or changing its score version.

Scores remain integer half points within the existing storage range. Only a
confirmed correction changes ratings, preserving notes and the diary dates
(`created_at` and `scored_at`). The sync version (`updated_at` / `updated_by`)
still advances, so corrections reach other devices without moving films in
date-based lists or recent-rating groups. The daily hint only states the
comparison allowance; sync details stay on the Sync screen.
Unsupported correction maps are rejected. Before saving, the store
rechecks both live score versions and whether the original or resulting pair
was already answered. The quota check, optional rescores and saved answer share
one transaction. A changed/deleted rating invalidates the pending pair rather
than applying a correction to an unseen version.

## Daily allowance

At most five completed comparisons are accepted per local calendar day,
including equal preference and answers that keep existing scores. Skipping
and leaving an unconfirmed choice do not spend the allowance. Closing and
reopening the section preserves the completed count; it does not start another
five-comparison session. Access returns on the next day, including after resume.
The screen's day-boundary timer stops while backgrounded and is disposed with
the route.

The count comes from retained comparison events and is shared after Drive
sync. Each device enforces its known history transactionally. Two disconnected
devices can together exceed five before merging; there is no server or global
reservation. Days are the local calendar labels saved when answering, rather
than a rolling 24-hour window. Restoring an older file retains known history
so it cannot reset the allowance.

## Selection

`selectCalibrationPair` operates on local live movie ratings and comparison
history. Canonical natural-key order keeps identity independent of poster
placement. Reviewed original/resulting versions and session skips are excluded.
A later score edit can make the pair eligible again; a note-only edit cannot.

Candidate generation uses bounded cyclic neighbours within score and genre
groups rather than constructing every possible pair. It considers up to eight
neighbours within each group and up to four matches against an adjacent score
group. A general group supplies candidates when genre evidence is missing.

Priority is ordered by:

1. A conflicting two-step chain of previous preferences.
2. Smaller score gap, so equal scores and half-point boundaries come first.
3. Fewer previous appearances, preferring less-reviewed movies.
4. Greater shared-genre overlap, then smaller known release-year distance.
5. Canonical natural pair ID as a deterministic tie-break.

For example, previous answers A > B and B > C can suggest comparing A with C
when their numeric scores do not reflect that ordering. Two equality answers
imply equality, not a strict preference. Chain evidence participates only while
its resulting score versions still match the current movies. It proposes a
question, never an automatic correction or a predicted personal score.

Selection uses no public ratings, catalog calls or randomness. Above 200
library rows it runs in a serialized worker; superseded results cannot replace
a newer selection. The screen retains a valid displayed pair during unrelated
updates and starts the next pair at the top. Large text uses a vertical movie
layout, and bottom padding keeps actions above either navigation style.

## Persistence and compatibility

The [data model](data-model.md#pair_comparisons) defines immutable event storage;
[sync](sync.md#format-rules) defines deterministic event merging, exports,
backups and compatibility. Events retain original and resulting score versions,
including the explicit equality choice. They can outlive deleted title snapshots
and are retained during replacement with an older file.

Regression coverage is indexed in [testing](testing.md#automated-coverage-by-behavior).
The selection rules are heuristics for useful questions, not a measured guarantee
of preference consistency or improved rating quality.
