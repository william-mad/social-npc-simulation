# Statistics Test (isolated prototype tool)

A small interactive statistical experiment that runs inside Godot, completely
separate from the game.

You enter 30 reference values (normally integers from -10 to +10, but any
numbers are accepted), then feed new values in one at a time. Each entry slides
a fixed-size **30-value rolling window** (drop oldest, append new) while the
**reference sample stays frozen**. After every entry the tool recomputes a
**Welch two-sample t-test** between the current window and the reference sample
and immediately redraws two frequency histograms.

Everything lives in this folder. Nothing outside `statistics_test/` was created
or modified, and deleting this folder removes the tool completely.

## Running it

The tool is a plain scene, so it needs no project-settings changes. Any of
these work:

- **Editor:** open `statistics_test/scenes/statistics_test.tscn` and press
  **F6** ("Run Current Scene", or the play icon next to the scene tab).
- **Command line:**

  ```sh
  godot --path . res://statistics_test/scenes/statistics_test.tscn
  ```

Optional conveniences:

```sh
# Preload a demo reference, submit a few demo rolls, and stay open:
godot --path . res://statistics_test/scenes/statistics_test.tscn -- --statistics-test-demo

# Same, but save a screenshot and exit (useful for automated checks):
godot --path . res://statistics_test/scenes/statistics_test.tscn -- --statistics-test-screenshot=C:/temp/statistics_test.png

# Screenshot of the setup phase (reference grid filled, experiment not started):
godot --path . res://statistics_test/scenes/statistics_test.tscn -- --statistics-test-screenshot-setup=C:/temp/statistics_test_setup.png

# Headless self-test (exits 0 on success, 1 on failure):
godot --headless -s res://statistics_test/self_test/statistics_self_test.gd
```

## How to use

1. **Setup phase** - type the 30 reference values into the grid (Enter jumps to
   the next field; invalid entries are highlighted red; the header counts how
   many of the 30 are valid). "Fill random (-10..10)" and "Clear" are
   conveniences. The **START EXPERIMENT** button stays disabled until all 30
   values are valid.
2. **Running phase** - the reference becomes fixed and the rolling window
   starts as an exact copy of it (so the initial t statistic is exactly 0).
   Type a value and press Enter (or "Submit", or "Random" for a random roll in
   [-10, 10]). Each roll removes the oldest window value, appends the new one,
   and updates everything: means, t statistic, p-value, both histograms, and
   the oldest->newest dump of the window. "Reset window" restarts the window
   as a copy of the unchanged reference.

**Multiple reference tables:** "[+] New table" reveals the entry grid again;
type 30 values (or use Fill random) and press "[+] ADD AS TABLE N" to store
them as an additional reference table. The "Reference table" dropdown
("Table 1", "Table 2", ...) chooses which stored table is the active
reference. Adding or switching tables never touches the rolling window - the
current sample keeps evolving across reference changes, and the t statistic is
simply recomputed against whichever table is active.

**Favor counter:** starts at 50. The [+] button next to it adds the current t
statistic to it (Favor += t), so it accumulates the signed deviations of the
rolling sample from the reference as you feed values in.

## Named, saved and editable tables

- **Naming**: the setup panel has a **Name** field used by START EXPERIMENT and
  [+] ADD AS TABLE. Session tables can be renamed any time in the **Tables...**
  popup; the dropdown, auto-switch targets and the data dump show the names.
- **Tables... popup**: lists the session tables and the saved library.
  - Session rows: rename inline, **Edit** (load the values into the entry
    grid, then **APPLY TO '<name>'** writes them back), **Save to file**
    (copy into the saved library, upserted by name), **X** (delete from the
    session; the last table cannot be deleted).
  - Saved rows: rename inline, **Edit** (grid -> **SAVE TO '<name>'** writes
    the file), **Use** (during a run: add to the session as the active
    reference; during setup: fill the grid for START), **X** (delete).
- **Storage**: the library lives in `statistics_test/saved_tables.json`
  (`{"tables": [{"name": ..., "values": [...]}, ...]}`), is auto-loaded at
  startup and re-written automatically after every library change. Deleting
  the statistics_test/ folder removes the file with the tool.

## Random generation and auto mode

The "Random generation" row (always visible) controls every random source in
the tool - "Fill random", the "Random" roll button, and auto mode:

- **weighted** (checkbox): when on, integer values in [-10, 10] are drawn with
  weights that fall off linearly around the **center** value
  (weight = spread - |value - center|), so the distribution's mean is exactly
  the center and sample means land close to it. **spread** controls how tight
  the cluster is: 0 always returns the center, larger spreads include more of
  the range. When off, values are uniform in [-10, 10].
- **auto every**: the interval used by auto mode.

**Auto mode:** "Auto: start" (next to Submit/Random) submits one random value
- weighted or uniform, per the settings - every interval. After each value,
*before the next one is generated*, its t statistic is added to Favor
automatically. "Auto: stop" halts it; the interval can be changed while it
runs.

**Auto-switch rules by Favor:** "Edit rules..." opens the rule editor; any
number of rules can be configured. Each rule has an enable checkbox, a
comparison (**>=** or **<=**), a **threshold**, and a target **table**.
Whenever Favor changes - manually via [+], or automatically after each auto
value - every enabled rule whose threshold Favor has crossed fires and makes
its target table the active reference (the rolling window is kept). The last
rule to fire wins, so an ascending ladder like "70 -> Table 2, 90 -> Table 3,
110 -> Table 4, ..." walks the reference up the ladder as Favor climbs. Each
rule fires once per crossing and re-arms automatically when Favor moves back
to the other side of its threshold. "[+] Add rule" adds more, "Re-arm all"
clears the fired flags, "X" deletes a rule, and new rules default to the
newest table.

Data lives in memory for the current session only; nothing is saved to disk.

## Output

- `t statistic` - the primary output, Welch two-sample t-test of current
  window vs. reference:
  - **positive t** -> current mean is **above** the reference mean
  - **negative t** -> current mean is **below** the reference mean
  - **t near 0** -> current mean is near the reference mean
- Supporting stats: reference/current mean, mean difference, std devs, standard
  error, degrees of freedom, and a two-tailed p-value (secondary output).
- `Favor` - a manual counter starting at 50; each press of its [+] button adds
  the current t statistic to it.
- `REFERENCE DISTRIBUTION` and `CURRENT DISTRIBUTION` histograms: one bar per
  integer value, x-axis always covers -10..+10 (extended automatically if data
  goes beyond), shared y-scale and a dashed mean marker on each graph.

## Implementation notes

- The two-sample t-test is Welch's (unequal variances), implemented directly in
  GDScript - this is **not** a one-sample test. The p-value comes from the
  t-distribution via a regularized incomplete beta function (Lanczos log-gamma
  + continued fraction), since Godot has no built-in. Anchors were verified
  against `scipy.stats` to ~1e-9.
- Degenerate cases are handled: identical constant samples give t = 0 / p = 1;
  constant samples with different means give signed infinity / p = 0.
- Non-integer entries are fine for the statistics; the histograms bin them at
  the nearest integer (the displayed statistics always use the exact values).
- The tool inherits the project-wide UI theme automatically; no theme files are
  touched.

## Files

```
statistics_test/
    scenes/
        statistics_test.tscn              entry scene (run this)
    scripts/
        statistics_test.gd                UI controller: setup, rolling input, display
        statistics_analyzer.gd            pure statistics (Welch t-test, p-value, frequencies)
        rolling_sample.gd                 fixed-size FIFO rolling window
        histogram_view.gd                 custom Control drawing one histogram via _draw()
    self_test/
        statistics_self_test.gd           headless checks (math + window + scene logic)
    README.md
```

Separation of concerns: statistical calculations (`statistics_analyzer.gd`),
rolling-window data handling (`rolling_sample.gd`), graph drawing
(`histogram_view.gd`), and the user interface (`statistics_test.gd` + scene)
are independent of each other and of the game.

## Removal

Delete the `statistics_test/` folder. That is the entire footprint - the tool
registers no global classes, no autoloads, and no project settings.

## Isolation guarantee

- No connections to combat, NPC, inventory, or any other game system.
- No existing script, scene, asset, or project setting was modified.
- Scripts are referenced only by relative `res://...` preloads
  within the folder; the game never loads anything from here.
