// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

import { OpenAI } from 'https://deno.land/x/openai@v4.56.0/mod.ts';
import { encode } from 'https://deno.land/std@0.138.0/encoding/base64.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const { image, type } = await req.json();

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  const openai = new OpenAI({ apiKey });

  var prompt = "Analyze the image that is attached. Answer according to the following criteria in pure json format with following fields: \"data\": \"<the data that is requested>\". ";

  if(type == "identify") {
    prompt += "Identify all objects within the image. Provide a JSON array as data containing the following fields for each object found: { \"object\": \"<the object>\", \"description\": \"<a small, simple and objective description of the object>\", \"number\": <how many of the same objects are there>}. Make the description simple. If no objects are found or the file is not an image, return null as data.";
  } else if(type == "license-plate") {
    prompt += "If the image contains an official license plate with visible numbers, provide the license plate number as data. If no visible official license plate is found or the file is not an image, return null as data.";
  } else {
    prompt += "Return null as data.";
  }

  console.log("Prompt:", prompt);

  const encodedFile = encode(image);

  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        "role": "system",
        "content": [
          { "type": "text", "text": "You are an AI assistant that helps analyze images based on certain criterias. The return type is a json object with the field data." }
        ]
      },
      {
        "role": "user",
        "content": [
          {
            "type": "image_url",
            "image_url": {
              "url": `data:image/jpeg;base64,${encodedFile}`,
            },
          },
          { 
            "type": "text", 
            "text": prompt 
          }
        ]
      }
    ],
    temperature: 0.0,
    top_p: 0.0,
    max_tokens: 300,
    stream: false,
  });

  console.log("Raw Response:", response);

  const rawContent = response.choices[0].message.content;
  console.log("Raw Content:", rawContent);

  const jsonString = rawContent.replace(/```json\n|```/g, '').replace(/\n/g, '');
  console.log("Cleaned JSON:", jsonString);

  return new Response(jsonString, { 
    headers: { ...corsHeaders, 'Content-Type': 'text/plain' },
    status: 200 
  });
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/analyze-image' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
