"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { MagicReveal } from "@/components/MagicReveal";
import { SketchCanvas, type SketchHandle } from "@/components/SketchCanvas";
import { Toolbar } from "@/components/Toolbar";
import { PEN_SIZES, PRESET_COLORS, type DrawMode } from "@/lib/drawing";

const PHRASES = [
  "Looking at your drawing",
  "Mixing a little magic",
  "Making it real",
  "Adding light and sparkle",
];

type Phase = "draw" | "conjuring" | "reveal";

export function DrawingStudio() {
  const sketchRef = useRef<SketchHandle>(null);
  const phaseRef = useRef<Phase>("draw");
  const [color, setColor] = useState<string>(PRESET_COLORS[6].hex);
  const [size, setSize] = useState<number>(PEN_SIZES[2].size);
  const [mode, setMode] = useState<DrawMode>("pen");
  const [history, setHistory] = useState({ canUndo: false, hasInk: false });
  const [phase, setPhase] = useState<Phase>("draw");
  const [phrase, setPhrase] = useState(PHRASES[0]);
  const [error, setError] = useState<string | null>(null);
  const [configured, setConfigured] = useState<boolean | null>(null);
  const [result, setResult] = useState<{ original: string; magic: string } | null>(null);

  phaseRef.current = phase;

  useEffect(() => {
    let cancelled = false;
    fetch("/api/magic")
      .then((response) => response.json())
      .then((data: { configured?: boolean }) => {
        if (!cancelled) setConfigured(Boolean(data.configured));
      })
      .catch(() => {
        if (!cancelled) setConfigured(null);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (phase !== "conjuring") return;
    setPhrase(PHRASES[0]);
    let index = 0;
    const timer = window.setInterval(() => {
      index = (index + 1) % PHRASES.length;
      setPhrase(PHRASES[index]);
    }, 2200);
    return () => window.clearInterval(timer);
  }, [phase]);

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (phaseRef.current !== "draw") return;
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "z") {
        event.preventDefault();
        sketchRef.current?.undo();
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const onSketchChange = useCallback((next: { canUndo: boolean; hasInk: boolean }) => {
    setHistory(next);
    setError(null);
  }, []);

  const closeReveal = useCallback(() => {
    setPhase("draw");
    setResult(null);
  }, []);

  const startOver = useCallback(() => {
    sketchRef.current?.clear();
    setPhase("draw");
    setResult(null);
  }, []);

  async function makeMagic() {
    const sketch = sketchRef.current;
    if (!sketch || sketch.isBlank()) {
      setError("Draw something first, then tap the magic button.");
      return;
    }

    const original = sketch.exportPng();
    setError(null);
    setPhase("conjuring");

    try {
      const response = await fetch("/api/magic", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ image: original }),
      });
      let payload: { image?: string; error?: string } = {};
      try {
        payload = (await response.json()) as { image?: string; error?: string };
      } catch {
        throw new Error("The magic got tangled. Try again in a moment.");
      }
      if (!response.ok || !payload.image) {
        throw new Error(payload.error || "The magic got tangled. Try again in a moment.");
      }
      setResult({ original, magic: payload.image });
      setPhase("reveal");
    } catch (caught) {
      setPhase("draw");
      if (caught instanceof TypeError) {
        setError("The magic can't reach the workshop. Check the connection and try again.");
        return;
      }
      setError(caught instanceof Error ? caught.message : "The magic got tangled. Try again in a moment.");
    }
  }

  return (
    <div className="app">
      <header className="header">
        <div className="brand">
          <BrandMark />
          <div>
            <h1>Movo Draw</h1>
            <p>Draw a picture. We&apos;ll turn it into something magical and real.</p>
          </div>
        </div>
        <button type="button" className="magic" onClick={makeMagic} disabled={phase === "conjuring"}>
          <SparkleIcon />
          {phase === "conjuring" ? "Making magic..." : "Make it magical"}
        </button>
      </header>

      {configured === false && (
        <p className="note" role="status">
          A grown-up needs to add a Replicate key before the magic can run.
        </p>
      )}
      {error && (
        <p className="note alert" role="alert">
          {error}
        </p>
      )}

      <div className="studio">
        <div className="frame">
          <div className="stage">
            <div className="paper" aria-busy={phase === "conjuring"}>
              <SketchCanvas
                ref={sketchRef}
                color={color}
                size={size}
                mode={mode}
                disabled={phase === "conjuring"}
                onChange={onSketchChange}
              />
              {!history.hasInk && phase === "draw" && (
                <div className="hint">
                  <strong>Draw here</strong>
                  <span>Use any colors you like</span>
                </div>
              )}
              {phase === "conjuring" && (
                <div className="conjure" role="status" aria-live="polite">
                  <div className="orb" aria-hidden="true" />
                  <p>{phrase}</p>
                  <span>This can take a few moments.</span>
                </div>
              )}
            </div>
          </div>
          <Toolbar
            color={color}
            size={size}
            mode={mode}
            canUndo={history.canUndo}
            hasInk={history.hasInk}
            onColor={setColor}
            onSize={setSize}
            onMode={setMode}
            onUndo={() => sketchRef.current?.undo()}
            onClear={() => sketchRef.current?.clear()}
          />
        </div>
      </div>

      {phase === "reveal" && result && (
        <MagicReveal original={result.original} magic={result.magic} onBack={closeReveal} onNew={startOver} />
      )}
    </div>
  );
}

function BrandMark() {
  return (
    <svg className="mark" viewBox="0 0 48 48" aria-hidden="true">
      <rect width="48" height="48" rx="16" fill="#ff5a36" />
      <circle cx="24" cy="23" r="10" fill="#ffe08a" />
      <circle cx="20.4" cy="21.5" r="1.4" fill="#3d2b24" />
      <circle cx="27.6" cy="21.5" r="1.4" fill="#3d2b24" />
      <path
        d="M19.8 26.2c1.1 1.6 2.4 2.3 4.2 2.3s3.1-.7 4.2-2.3"
        fill="none"
        stroke="#3d2b24"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  );
}

function SparkleIcon() {
  return (
    <svg className="sparkle" viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="currentColor"
        d="M12 2.2 13.8 8l5.9 1.2-5.9 1.6L12 16.6 10.2 10.8 4.3 9.2 10.2 8 12 2.2Zm6.2 11.2.8 2.4 2.5.5-2.5.7-.8 2.4-.7-2.4-2.4-.7 2.4-.5.7-2.4Z"
      />
    </svg>
  );
}
