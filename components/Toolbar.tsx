"use client";

import { useEffect, useRef, useState } from "react";
import { ColorWheel } from "@/components/ColorWheel";
import { PEN_SIZES, PRESET_COLORS, type DrawMode } from "@/lib/drawing";

type ToolbarProps = {
  color: string;
  size: number;
  mode: DrawMode;
  canUndo: boolean;
  hasInk: boolean;
  onColor: (hex: string) => void;
  onSize: (size: number) => void;
  onMode: (mode: DrawMode) => void;
  onUndo: () => void;
  onClear: () => void;
};

export function Toolbar({
  color,
  size,
  mode,
  canUndo,
  hasInk,
  onColor,
  onSize,
  onMode,
  onUndo,
  onClear,
}: ToolbarProps) {
  const [open, setOpen] = useState(false);
  const [confirmClear, setConfirmClear] = useState(false);
  const confirmRef = useRef(false);
  const rootRef = useRef<HTMLElement>(null);
  const selectedSize = PEN_SIZES.find((pen) => pen.size === size) ?? PEN_SIZES[2];
  const named = PRESET_COLORS.find((swatch) => swatch.hex.toLowerCase() === color.toLowerCase());
  const toolName = mode === "eraser" ? "Erase" : "Draw";

  useEffect(() => {
    if (!confirmClear) return;
    const timeout = window.setTimeout(() => {
      confirmRef.current = false;
      setConfirmClear(false);
    }, 5000);
    return () => window.clearTimeout(timeout);
  }, [confirmClear]);

  useEffect(() => {
    if (!open) return;
    const motion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    rootRef.current?.scrollIntoView({ block: "start", behavior: motion ? "auto" : "smooth" });
  }, [open]);

  useEffect(() => {
    if (!open) return;
    function onPointerDown(event: PointerEvent) {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    }
    function onKey(event: KeyboardEvent) {
      if (event.key === "Escape") setOpen(false);
    }
    document.addEventListener("pointerdown", onPointerDown, true);
    window.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("pointerdown", onPointerDown, true);
      window.removeEventListener("keydown", onKey);
    };
  }, [open]);

  return (
    <aside className={open ? "toolbar open" : "toolbar"} aria-label="Drawing tools" ref={rootRef}>
      <button
        type="button"
        className="toolbar-toggle"
        aria-expanded={open}
        aria-controls="tool-panel"
        onClick={() => setOpen((value) => !value)}
      >
        <span
          className={mode === "eraser" ? "toggle-swatch eraser" : "toggle-swatch"}
          style={{ background: mode === "eraser" ? "#ffffff" : color }}
          aria-hidden="true"
        />
        <span className="toggle-copy">
          <strong>{toolName}</strong>
          <span>{selectedSize.label}</span>
        </span>
        <ChevronIcon />
      </button>

      <div id="tool-panel" className="tool-panel" inert={!open}>
        <div className="tool-panel-body">
        <div className="tool-stack">
        <div>
          <h2 className="tool-label">Tool</h2>
          <div className="modes" role="radiogroup" aria-label="Draw or erase">
            <button
              type="button"
              className="mode"
              role="radio"
              aria-checked={mode === "pen"}
              onClick={() => onMode("pen")}
            >
              <PencilIcon />
              Draw
            </button>
            <button
              type="button"
              className="mode"
              role="radio"
              aria-checked={mode === "eraser"}
              onClick={() => onMode("eraser")}
            >
              <EraserIcon />
              Erase
            </button>
          </div>
        </div>

        <div>
          <h2 className="tool-label">Pen size · {selectedSize.label}</h2>
          <div className="sizes" role="radiogroup" aria-label="Pen size">
            {PEN_SIZES.map((pen) => {
              const light = color.toLowerCase() === "#ffffff" || mode === "eraser";
              return (
                <button
                  key={pen.id}
                  type="button"
                  className="size"
                  role="radio"
                  aria-checked={size === pen.size}
                  aria-label={pen.label}
                  onClick={() => onSize(pen.size)}
                >
                  <span
                    style={{
                      width: Math.min(pen.dot, 18),
                      height: Math.min(pen.dot, 18),
                      background: mode === "eraser" ? "#ffffff" : color,
                      boxShadow: light ? "inset 0 0 0 1.5px #d6d3d1" : undefined,
                    }}
                  />
                </button>
              );
            })}
          </div>
        </div>

        <div>
          <h2 className="tool-label">Colors</h2>
          <div className="swatches" role="radiogroup" aria-label="Colors">
            {PRESET_COLORS.map((swatch) => (
              <button
                key={swatch.hex}
                type="button"
                className="swatch"
                role="radio"
                aria-checked={color.toLowerCase() === swatch.hex}
                aria-label={swatch.name}
                style={{ background: swatch.hex }}
                onClick={() => {
                  onMode("pen");
                  onColor(swatch.hex);
                }}
              />
            ))}
          </div>
        </div>

        <div className="actions">
          <button type="button" className="quiet" onClick={onUndo} disabled={!canUndo}>
            Undo
          </button>
          <button
            type="button"
            className={confirmClear ? "quiet armed" : "quiet"}
            onClick={() => {
              if (!confirmRef.current) {
                confirmRef.current = true;
                setConfirmClear(true);
                return;
              }
              confirmRef.current = false;
              setConfirmClear(false);
              onClear();
            }}
            disabled={!hasInk}
          >
            {confirmClear ? "Sure?" : "Clear"}
          </button>
        </div>
        </div>

        <div className="tool-wheel">
          <h2 className="tool-label">Color wheel</h2>
          <ColorWheel
            color={color}
            onChange={(hex) => {
              onMode("pen");
              onColor(hex);
            }}
          />
          <div className="mix-readout">
            <span className="preview" style={{ background: color }} />
            <p>{mode === "eraser" ? "Eraser" : named ? named.name : "Mixed color"}</p>
          </div>
        </div>
        </div>
      </div>
    </aside>
  );
}

function ChevronIcon() {
  return (
    <svg className="chevron" viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M6 9.5 12 15l6-5.5"
      />
    </svg>
  );
}

function PencilIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="currentColor"
        d="M14.1 3.5a1.8 1.8 0 0 1 2.5 0l3.9 3.9a1.8 1.8 0 0 1 0 2.5L9.2 21.2 3 22.9l1.7-6.2L14.1 3.5Zm2.5 1.4-1.2 1.2 3.5 3.5 1.2-1.2-3.5-3.5ZM6.2 16.4l3.4 3.4.8-2.6-1.6-1.6-2.6.8Z"
      />
    </svg>
  );
}

function EraserIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="currentColor"
        d="M15.9 3.4a2 2 0 0 1 2.8 0l2 2a2 2 0 0 1 0 2.8l-8.2 8.3H8.2L3.6 12a2 2 0 0 1 0-2.8l6.5-5.8a2 2 0 0 1 2.7.1l3.1-.1Zm-1.2 2.6L8.4 12.2l3.4 3.4 6.3-6.2-3.4-3.4ZM4.8 14.2l2.6 2.6h3.2l-1.5-1.5-4.3-1.1Z"
      />
    </svg>
  );
}
