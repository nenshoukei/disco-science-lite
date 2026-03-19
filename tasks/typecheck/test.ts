/**
 * Type-checking tests for disco-science-lite.d.ts
 *
 * Run: make typecheck
 */

// ---------------------------------------------------------------------------
// DiscoScience (prototype stage API)
// ---------------------------------------------------------------------------

// prepareLab: basic usage
DiscoScience.prepareLab({ type: "lab", name: "my-lab" });
DiscoScience.prepareLab({ type: "lab", name: "my-lab" }, {});
DiscoScience.prepareLab({ type: "lab", name: "my-lab" }, { animation: "my-anim" });

// prepareLab: structural compatibility — a superset of { type: "lab", name: string }
// simulates passing an actual LabPrototype from typed-factorio or factorio-types
const mockLabPrototype = {
  type: "lab" as const,
  name: "my-lab",
  ingredients: [{ type: "item" as const, name: "science-pack-1", amount: 1 }],
  energy_usage: "100kW",
};
DiscoScience.prepareLab(mockLabPrototype);

// prepareLab: errors
// @ts-expect-error - missing required `name`
DiscoScience.prepareLab({ type: "lab" });

// @ts-expect-error - `type` is not "lab"
DiscoScience.prepareLab({ type: "item", name: "my-lab" });

// @ts-expect-error - unknown settings key
DiscoScience.prepareLab({ type: "lab", name: "my-lab" }, { unknown: true });

// ---------------------------------------------------------------------------
// DiscoScience.PrepareLabSettings type
// ---------------------------------------------------------------------------

const settings1: DiscoScience.PrepareLabSettings = {};
const settings2: DiscoScience.PrepareLabSettings = { animation: "my-anim" };

// @ts-expect-error - unknown key
const _settings3: DiscoScience.PrepareLabSettings = { unknown: true };

// ---------------------------------------------------------------------------
// DiscoScience.Color type
// ---------------------------------------------------------------------------

const color1: DiscoScience.Color = { r: 1, g: 0, b: 0 };
const color2: DiscoScience.Color = { r: 1, g: 0, b: 0, a: 1 };
const color3: DiscoScience.Color = {};
const color4: DiscoScience.Color = [1, 0, 0];
const color5: DiscoScience.Color = [1, 0, 0, 1];

// @ts-expect-error - 2-tuple is not Color
const _color6: DiscoScience.Color = [1, 0];

// ---------------------------------------------------------------------------
// DiscoScience.Remote interface
// ---------------------------------------------------------------------------

// Verify the interface shape (without calling remote.call, which needs typed-factorio)
const remote: DiscoScience.Remote = {
  setLabScale: (lab_name: string, scale: number) => {},
  setIngredientColor: (item_name: string, color: DiscoScience.Color) => {},
  getIngredientColor: (item_name: string) => undefined,
};

remote.setLabScale("my-lab", 2);
remote.setIngredientColor("iron-plate", { r: 1 });
remote.setIngredientColor("iron-plate", [1, 0, 0]);
const remoteColor: DiscoScience.Color | undefined = remote.getIngredientColor("iron-plate");

// suppress unused variable warnings
void color1; void color2; void color3; void color4; void color5;
void settings1; void settings2; void remote; void remoteColor;
