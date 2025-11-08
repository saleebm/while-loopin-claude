#!/usr/bin/env bun
/**
 * Extract structured analysis data from prompt for smart-agent.sh
 * Uses AI SDK generateObject for guaranteed structured JSON output
 */

import { generateObject } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { readFileSync } from "fs";
import { z } from "zod";

// Schema for analysis data
const analysisSchema = z.object({
  feature_name: z.string().describe("Kebab-case feature directory name"),
  prompt_type: z.string().describe("Specific description of the task type"),
  complexity: z.number().min(1).max(10).describe("Task complexity from 1-10"),
  estimated_complexity: z.enum(["low", "medium", "high", "very-high"]).describe("Complexity category"),
  max_iterations: z.number().min(1).max(50).describe("Recommended max iterations"),
  enable_code_review: z.boolean().describe("Whether code review should be enabled"),
  max_reviews: z.number().min(1).max(10).describe("Maximum number of code review cycles"),
  use_master_agent: z.boolean().describe("Whether to use multi-phase master agent"),
  relevant_files: z.array(z.string()).describe("List of files likely relevant to this task"),
  enhanced_prompt: z.string().describe("Enhanced version of the prompt with full context"),
  initial_handoff: z.string().describe("Initial handoff document content"),
  reasoning: z.string().describe("Explanation of why these settings were chosen"),
});

type AnalysisData = z.infer<typeof analysisSchema>;

async function extractAnalysisData(promptFile: string): Promise<any> {
  // Read the user's prompt
  const promptContent = readFileSync(promptFile, "utf-8");

  // Use generateObject to extract structured data
  const { object } = await generateObject({
    model: anthropic("claude-3-5-sonnet-20241022"),
    schema: analysisSchema,
    maxTokens: 4096,
    prompt: `Analyze this prompt and return a structured JSON configuration for running an autonomous agent.

User's Prompt:
${promptContent}

Your Task:
1. What type of task is this? (be specific and creative - don't just say "bug fix" or "feature", describe it precisely)
2. What should the feature folder be named? (kebab-case slug)
3. What files are likely relevant to this task?
4. How complex is this task? (estimate iterations needed, 1-50)
5. What is the complexity category? (low/medium/high/very-high)
6. Should this include code review?
7. Should this use the master agent for multi-phase orchestration? (true for very complex, multi-part tasks)
8. Create an enhanced version of the prompt with full context
9. Write an initial handoff document

For use_master_agent, return true if:
- Task requires multiple distinct phases (e.g., "build complete auth system")
- Has complex dependencies between components
- Needs coordinated work across different subsystems
- Has estimated_complexity of "very-high"

Return false for simple, single-focused tasks.

Return structured data matching the schema.`,
  });

  return object;
}

// Main execution
if (import.meta.main) {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.error("Usage: extract-analysis-json.ts <prompt-file>");
    process.exit(1);
  }

  const [promptFile] = args;

  try {
    const result = await extractAnalysisData(promptFile);
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error("Error extracting analysis data:", error);
    // Output minimal valid JSON on error
    console.log(JSON.stringify({
      feature_name: "task",
      prompt_type: "General task",
      complexity: 5,
      estimated_complexity: "medium",
      max_iterations: 10,
      enable_code_review: true,
      max_reviews: 3,
      use_master_agent: false,
      relevant_files: [],
      enhanced_prompt: readFileSync(promptFile, "utf-8"),
      initial_handoff: "# Agent Handoff\n\n## Session End\nStatus: starting\n\n## Task\nStarting new task",
      reasoning: "Using default settings due to analysis error",
      error: true,
    }));
    process.exit(1);
  }
}

export { extractAnalysisData, analysisSchema };

