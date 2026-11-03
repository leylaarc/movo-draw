"use client";

import { forwardRef, useEffect, useImperativeHandle, useRef } from "react";
import { CANVAS_HEIGHT, CANVAS_WIDTH, PAPER_COLOR, type DrawMode } from "@/lib/drawing";

export type SketchHandle = {
  exportPng: () => string;
  isBlank: () => boolean;
  undo: () => void;
  clear: () => void;
};

type SketchCanvasProps = {
  color: string;
  size: number;
  mode: DrawMode;
  disabled?: boolean;
  onChange: (state: { canUndo: boolean; hasInk: boolean }) => void;
};

type Point = { x: number; y: number };

const MAX_UNDO = 12;

export const SketchCanvas = forwardRef<SketchHandle, SketchCanvasProps>(function SketchCanvas(
  { color, size, mode, disabled = false, onChange },
  ref,
) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const undoRef = useRef<ImageData[]>([]);
  const drawingRef = useRef(false);
  const pointerRef = useRef<number | null>(null);
  const pointsRef = useRef<Point[]>([]);
  const propsRef = useRef({ color, size, mode, onChange });
  propsRef.current = { color, size, mode, onChange };

  useEffect(() => {
    const canvas = canvasRef.current;
    const context = canvas?.getContext("2d", { willReadFrequently: true });
    if (!canvas || !context) return;
    canvas.width = CANVAS_WIDTH;
    canvas.height = CANVAS_HEIGHT;
    undoRef.current = [];
    fillPaper(context);
  }, []);

  useImperativeHandle(ref, () => ({
    exportPng() {
      return canvasRef.current?.toDataURL("image/png") ?? "";
    },
    isBlank,
    undo() {
      const snapshot = undoRef.current.pop();
      const context = getContext();
      if (!snapshot || !context) return;
      context.putImageData(snapshot, 0, 0);
      report();
    },
    clear() {
      const context = getContext();
      if (!context) return;
      pushUndo();
      fillPaper(context);
      report();
    },
  }));

  function getContext() {
    return canvasRef.current?.getContext("2d") ?? null;
  }

  function fillPaper(context: CanvasRenderingContext2D) {
    context.fillStyle = PAPER_COLOR;
    context.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
  }

  function pushUndo() {
    const context = getContext();
    if (!context) return;
    undoRef.current.push(context.getImageData(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT));
    if (undoRef.current.length > MAX_UNDO) undoRef.current.shift();
  }

  function applyStyle(context: CanvasRenderingContext2D) {
    const current = propsRef.current;
    context.lineCap = "round";
    context.lineJoin = "round";
    context.strokeStyle = current.mode === "eraser" ? PAPER_COLOR : current.color;
    context.fillStyle = context.strokeStyle;
    context.lineWidth = current.mode === "eraser" ? current.size * 1.7 : current.size;
  }

  function isBlank() {
    const canvas = canvasRef.current;
    if (!canvas) return true;
    const probe = document.createElement("canvas");
    probe.width = 256;
    probe.height = 192;
    const context = probe.getContext("2d", { willReadFrequently: true });
    if (!context) return false;
    context.drawImage(canvas, 0, 0, probe.width, probe.height);
    const { data } = context.getImageData(0, 0, probe.width, probe.height);
    for (let index = 0; index < data.length; index += 4) {
      if (data[index] < 248 || data[index + 1] < 248 || data[index + 2] < 248) return false;
    }
    return true;
  }

  function report() {
    propsRef.current.onChange({
      canUndo: undoRef.current.length > 0,
      hasInk: !isBlank(),
    });
  }

  function pointFrom(event: PointerEvent | React.PointerEvent<HTMLDivElement>): Point | null {
    const canvas = canvasRef.current;
    if (!canvas) return null;
    const bounds = canvas.getBoundingClientRect();
    if (bounds.width === 0 || bounds.height === 0) return null;
    return {
      x: ((event.clientX - bounds.left) / bounds.width) * canvas.width,
      y: ((event.clientY - bounds.top) / bounds.height) * canvas.height,
    };
  }

  function drawDot(point: Point) {
    const context = getContext();
    if (!context) return;
    applyStyle(context);
    context.beginPath();
    context.arc(point.x, point.y, context.lineWidth / 2, 0, Math.PI * 2);
    context.fill();
  }

  function addPoint(point: Point) {
    const points = pointsRef.current;
    points.push(point);
    const context = getContext();
    if (!context) return;
    applyStyle(context);

    if (points.length < 3) {
      const previous = points[points.length - 2] ?? point;
      context.beginPath();
      context.moveTo(previous.x, previous.y);
      context.lineTo(point.x, point.y);
      context.stroke();
      return;
    }

    const first = points[points.length - 3];
    const middle = points[points.length - 2];
    const last = points[points.length - 1];
    context.beginPath();
    context.moveTo((first.x + middle.x) / 2, (first.y + middle.y) / 2);
    context.quadraticCurveTo(middle.x, middle.y, (middle.x + last.x) / 2, (middle.y + last.y) / 2);
    context.stroke();
  }

  function endStroke() {
    if (!drawingRef.current) return;
    const points = pointsRef.current;
    if (points.length >= 2) {
      const middle = points[points.length - 2];
      const last = points[points.length - 1];
      const context = getContext();
      if (context) {
        applyStyle(context);
        context.beginPath();
        context.moveTo((middle.x + last.x) / 2, (middle.y + last.y) / 2);
        context.lineTo(last.x, last.y);
        context.stroke();
      }
    }
    drawingRef.current = false;
    pointerRef.current = null;
    pointsRef.current = [];
    report();
  }

  function onPointerDown(event: React.PointerEvent<HTMLDivElement>) {
    if (disabled || event.button !== 0) return;
    const point = pointFrom(event);
    if (!point) return;
    try {
      event.currentTarget.setPointerCapture(event.pointerId);
    } catch {
      // Capture is only available for a real, active pointer.
    }
    pointerRef.current = event.pointerId;
    drawingRef.current = true;
    pointsRef.current = [];
    pushUndo();
    drawDot(point);
    pointsRef.current.push(point);
  }

  function onPointerMove(event: React.PointerEvent<HTMLDivElement>) {
    if (!drawingRef.current || pointerRef.current !== event.pointerId) return;
    const coalesced = event.nativeEvent.getCoalescedEvents?.() ?? [];
    const samples = coalesced.length > 0 ? coalesced : [event.nativeEvent];
    for (const sample of samples) {
      const point = pointFrom(sample);
      if (point) addPoint(point);
    }
  }

  function onPointerUp(event: React.PointerEvent<HTMLDivElement>) {
    if (pointerRef.current !== event.pointerId) return;
    try {
      if (event.currentTarget.hasPointerCapture(event.pointerId)) {
        event.currentTarget.releasePointerCapture(event.pointerId);
      }
    } catch {
      // The pointer may already have been released.
    }
    endStroke();
  }

  return (
    <div
      className={mode === "eraser" ? "sheet erasing" : "sheet"}
      role="application"
      tabIndex={0}
      aria-label="Drawing paper"
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
      onLostPointerCapture={endStroke}
      onContextMenu={(event) => event.preventDefault()}
    >
      <canvas ref={canvasRef} className="sketch" aria-hidden="true" />
    </div>
  );
});
