export const PAPER_COLOR = "#ffffff";

export const CANVAS_WIDTH = 1024;
export const CANVAS_HEIGHT = 768;

export type DrawMode = "pen" | "eraser";

export const PEN_SIZES = [
  { id: "tiny", label: "Tiny", size: 4, dot: 6 },
  { id: "small", label: "Small", size: 10, dot: 10 },
  { id: "medium", label: "Medium", size: 18, dot: 16 },
  { id: "big", label: "Big", size: 32, dot: 22 },
  { id: "giant", label: "Giant", size: 54, dot: 30 },
] as const;

export const PRESET_COLORS = [
  { name: "Black", hex: "#241c18" },
  { name: "White", hex: "#ffffff" },
  { name: "Red", hex: "#ff3b30" },
  { name: "Orange", hex: "#ff8a00" },
  { name: "Yellow", hex: "#ffd000" },
  { name: "Green", hex: "#22b573" },
  { name: "Blue", hex: "#2f80ff" },
  { name: "Purple", hex: "#8b5cff" },
  { name: "Pink", hex: "#ff4f93" },
  { name: "Brown", hex: "#8d5a3b" },
] as const;
