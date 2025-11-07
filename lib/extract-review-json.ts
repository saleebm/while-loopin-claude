#!/usr/bin/env bun
/**
 * Extract structured review data from Claude review output
 * Uses AI SDK generateObject for guaranteed structured JSON output
 */

import { generateObject } from "ai";
import { anthropic } from "@ai-sdk/anthropic";
import { readFileSync } from "fs";
import { z } from "zod";

// Schema for review data extraction
const reviewSchema = z.object({
  speech: z.string().describe("A concise 1-sentence summary (max 15 words) to speak out loud"),
  score: z.number().min(0).max(10).describe("Quality score from 0-10"),
  critical_fixes: z.array(z.string()).describe("List of critical issues that must be fixed"),
  suggestions: z.array(z.string()).describe("List of optional improvements"),
  summary: z.string().describe("2-3 sentence overview of the review"),
});

type ReviewData = z.infer<typeof reviewSchema>;

async function extractReviewData(inputFile: string, additionalJson?: string): Promise<any> {
  // Read the review output
  const reviewContent = readFileSync(inputFile, "utf-8");

  // Parse additional JSON if provided
  let additionalData: Record<string, any> = {};
  if (additionalJson && additionalJson !== "{}") {
    try {
      additionalData = JSON.parse(additionalJson);
    } catch (e) {
      console.error("Warning: Failed to parse additional JSON", e);
    }
  }

  // Use generateObject to extract structured data
  const { object } = await generateObject({
    model: anthropic("claude-3-5-haiku-20241022"),
    schema: reviewSchema,
    prompt: `Analyze this code review output and extract structured data.

Review Output:
${reviewContent}

Extract:
1. A concise speech summary (max 15 words)
2. Quality score (0-10)
3. Critical fixes that MUST be addressed (empty array if none)
4. Optional suggestions for improvement (empty array if none)
5. A 2-3 sentence summary of the review

Respond with JSON matching the schema.`,
  });

  // Merge with additional data (additional data adds extra fields, doesn't override extracted data)
  return {
    ...additionalData,
    ...object,
  };
}

// Main execution
if (import.meta.main) {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.error("Usage: extract-review-json.ts <input-file> [additional-json]");
    process.exit(1);
  }

  const [inputFile, additionalJson] = args;

  try {
    const result = await extractReviewData(inputFile, additionalJson);
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error("Error extracting review data:", error);
    // Output minimal valid JSON on error
    console.log(JSON.stringify({
      speech: "Processing complete",
      score: 0,
      critical_fixes: [],
      suggestions: [],
      summary: "Error processing review",
      error: true,
    }));
    process.exit(1);
  }
}

export { extractReviewData, reviewSchema };

