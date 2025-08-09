# enhanced_t5_recipe_handler.py
# Enhanced T5 handler with structured prompting for better recipe generation

import torch
from transformers import T5ForConditionalGeneration, T5Tokenizer
import logging

logger = logging.getLogger(__name__)

class EnhancedT5RecipeHandler:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model_path = "./t5Model"  # Path to your trained model
        
        # Comprehensive recipe generation prompt
        self.recipe_prompt_template = """## ROLE & PURPOSE:

You are a **professional culinary recipe generation AI** trained to create **clear, accurate, and well-structured cooking recipes** from a given list of ingredients. Your role is to **transform the raw list into a complete, high-quality recipe** that is easy to follow, properly formatted, and suitable for real-world cooking.

You must provide **detailed cooking steps**, realistic measurements, and sensible preparation methods based strictly on the provided ingredients, with optional enhancements suggested only if explicitly allowed.

The recipes you create should reflect **culinary expertise**, **balance of flavors**, and **practical cooking techniques**.

## CRITICAL RULES:

1. **Never hallucinate ingredients** — use only the ingredients provided unless allowed to add "common kitchen essentials" (water, salt, pepper, oil, butter) for practicality.
2. **Assign realistic quantities** — use standard measurement units (cups, teaspoons, grams, ml, etc.).
3. **Maintain logical cooking order** — prep before cooking, cook before serving.
4. **Include clear, numbered steps** — each step should describe exactly what is done, in the correct order.
5. **Include preparation and cooking times** — estimate realistically.
6. **Include serving size** — e.g., "Serves 4".
7. **Ensure flavor and texture balance** — consider seasoning, cooking techniques, and complementary textures.
8. **No unnecessary repetition** — do not redundantly list the same ingredient in multiple unrelated steps without reason.
9. **Avoid vague directions** — use precise verbs (sauté, simmer, whisk, fold) instead of generic "cook" or "do".
10. **Output in a structured, consistent format**.

## RECIPE FORMAT:

Your recipe output must follow this structure exactly:

### Recipe Title:
[Creative but relevant title, based on main ingredients]

### Description:
[A short, enticing summary of the dish, including flavor notes and potential meal occasions.]

### Ingredients:
- [Quantity] [Ingredient name]
- [Quantity] [Ingredient name]
...

### Instructions:
1. [Detailed step — include action, ingredient(s), method, and any timing/temperature info]
2. [Detailed step]
3. ...

### Prep Time:
[Number] minutes

### Cook Time:
[Number] minutes

### Total Time:
[Number] minutes

### Servings:
[Number of servings]

### Chef's Tips:
- [Optional tip to improve the recipe — cooking trick, plating advice, or variation]

## GENERATE RECIPE FOR THESE INGREDIENTS: {ingredients}

Please create a complete, professional recipe following all the above guidelines."""

    def load_model(self):
        try:
            logger.info(f"Loading Enhanced T5 model from {self.model_path}")
            logger.info(f"Using device: {self.device}")
            
            # Load tokenizer and model with multiple fallback approaches
            model_loaded = False
            
            # Try multiple loading approaches
            approaches = [
                {"use_safetensors": True, "local_files_only": True},
                {"use_safetensors": False, "local_files_only": True},
                {"local_files_only": True}
            ]
            
            for i, approach in enumerate(approaches):
                try:
                    logger.info(f"Loading attempt {i+1}: {approach}")
                    self.tokenizer = T5Tokenizer.from_pretrained(self.model_path, **approach)
                    self.model = T5ForConditionalGeneration.from_pretrained(self.model_path, **approach)
                    model_loaded = True
                    logger.info(f"Model loaded successfully with approach {i+1}")
                    break
                except Exception as e:
                    logger.warning(f"Approach {i+1} failed: {e}")
            
            if not model_loaded:
                raise Exception("All loading approaches failed")
            
            # Move model to device and set to evaluation mode
            self.model.to(self.device)
            self.model.eval()
            
            logger.info("Enhanced T5 model loaded and ready for recipe generation")
            
        except Exception as e:
            logger.error(f"Failed to load model: {str(e)}")
            raise e
    
    def is_loaded(self) -> bool:
        return self.model is not None and self.tokenizer is not None
    
    def generate_recipe_with_structured_prompt(self, ingredients: str, max_length: int = 1000, temperature: float = 0.7) -> str:
        """Generate a recipe using the comprehensive structured prompt"""
        if not self.is_loaded():
            raise ValueError("Model not loaded")
        
        try:
            # Create the full structured prompt
            full_prompt = self.recipe_prompt_template.format(ingredients=ingredients)
            
            # For T5, we need to use a task prefix - let's try different approaches
            prompts_to_try = [
                f"generate detailed recipe: {ingredients}",  # Original training format
                f"create recipe: {ingredients}",             # Alternative format
                f"recipe for: {ingredients}",                # Simple format
                full_prompt,                                 # Full structured prompt
            ]
            
            best_result = ""
            best_length = 0
            
            for i, prompt in enumerate(prompts_to_try):
                try:
                    logger.info(f"Trying prompt approach {i+1}/{len(prompts_to_try)}")
                    
                    # Tokenize the prompt
                    inputs = self.tokenizer.encode(
                        prompt,
                        return_tensors="pt",
                        max_length=512,  # T5 input limit
                        truncation=True
                    ).to(self.device)
                    
                    # Generate with optimized parameters for recipe generation
                    with torch.no_grad():
                        outputs = self.model.generate(
                            inputs,
                            max_length=max_length,
                            min_length=50,  # Ensure minimum output length
                            temperature=temperature,
                            do_sample=True,
                            pad_token_id=self.tokenizer.pad_token_id,
                            eos_token_id=self.tokenizer.eos_token_id,
                            num_return_sequences=1,
                            
                            # Parameters to improve quality and reduce repetition
                            repetition_penalty=1.3,
                            no_repeat_ngram_size=3,
                            length_penalty=1.1,  # Encourage longer outputs
                            
                            # Sampling parameters for creativity while maintaining coherence
                            top_p=0.9,
                            top_k=50,
                            
                            # Use beam search for better quality at lower temperatures
                            num_beams=3 if temperature < 0.5 else 1,
                            early_stopping=True
                        )
                    
                    # Decode the result
                    generated_text = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
                    
                    # Post-process the result
                    processed_text = self._post_process_recipe_output(generated_text, ingredients)
                    
                    # Keep track of the best result (longest, most detailed)
                    if len(processed_text) > best_length and len(processed_text) > 50:
                        best_result = processed_text
                        best_length = len(processed_text)
                        logger.info(f"New best result from approach {i+1}: {len(processed_text)} characters")
                    
                    # If we get a good result early, we can break
                    if len(processed_text) > 200 and "###" in processed_text:
                        logger.info(f"Found structured result from approach {i+1}, using it")
                        best_result = processed_text
                        break
                        
                except Exception as e:
                    logger.warning(f"Prompt approach {i+1} failed: {e}")
                    continue
            
            if not best_result:
                # Fallback: create a basic structured recipe
                logger.warning("All generation attempts failed, creating fallback recipe")
                best_result = self._create_fallback_recipe(ingredients)
            
            return best_result
            
        except Exception as e:
            logger.error(f"Recipe generation failed: {str(e)}")
            # Return a fallback recipe instead of failing completely
            return self._create_fallback_recipe(ingredients)
    
    def _post_process_recipe_output(self, text: str, original_ingredients: str) -> str:
        """Clean up and structure the generated recipe text"""
        if not text:
            return text
        
        # Remove excessive repetitions of words
        words = text.split()
        cleaned_words = []
        recent_words = []
        
        for word in words:
            # Skip if this word appeared too recently
            if recent_words.count(word) < 2:  # Allow up to 2 occurrences in recent context
                cleaned_words.append(word)
            recent_words.append(word)
            if len(recent_words) > 10:  # Keep only last 10 words in memory
                recent_words.pop(0)
        
        cleaned_text = " ".join(cleaned_words)
        
        # If the output doesn't contain proper structure, try to add it
        if "###" not in cleaned_text and "Recipe" not in cleaned_text:
            # Try to structure the output
            structured = self._add_basic_structure(cleaned_text, original_ingredients)
            return structured
        
        # Basic formatting improvements
        lines = cleaned_text.split('\n')
        improved_lines = []
        
        for line in lines:
            line = line.strip()
            if line:
                # Capitalize first letter of sentences
                if line and not line.startswith('#'):
                    line = line[0].upper() + line[1:] if len(line) > 1 else line.upper()
                improved_lines.append(line)
        
        return '\n'.join(improved_lines)
    
    def _add_basic_structure(self, text: str, ingredients: str) -> str:
        """Add basic recipe structure to unstructured text"""
        # Create a simple structured version
        recipe_title = f"Recipe using {ingredients.replace(',', ', ')}"
        
        structured = f"""### Recipe Title:
{recipe_title}

### Description:
A delicious dish made with {ingredients}.

### Ingredients:
{self._format_ingredients(ingredients)}

### Instructions:
{self._format_instructions(text)}

### Prep Time:
15 minutes

### Cook Time:
25 minutes

### Total Time:
40 minutes

### Servings:
2-4

### Chef's Tips:
- Season to taste with salt and pepper
- Adjust cooking times based on your preferences"""
        
        return structured
    
    def _format_ingredients(self, ingredients_str: str) -> str:
        """Format ingredients list with basic measurements"""
        ingredients = [ing.strip() for ing in ingredients_str.split(',')]
        formatted = []
        
        # Basic measurement assignments
        measurements = {
            'chicken': '2 chicken breasts',
            'beef': '1 lb ground beef',
            'rice': '1 cup rice',
            'pasta': '8 oz pasta',
            'onion': '1 medium onion',
            'garlic': '3 cloves garlic',
            'tomato': '2 medium tomatoes',
            'cheese': '1/2 cup cheese'
        }
        
        for ingredient in ingredients:
            # Check if we have a standard measurement
            found_measurement = False
            for key, measurement in measurements.items():
                if key in ingredient.lower():
                    formatted.append(f"- {measurement}")
                    found_measurement = True
                    break
            
            if not found_measurement:
                formatted.append(f"- {ingredient}")
        
        return '\n'.join(formatted)
    
    def _format_instructions(self, text: str) -> str:
        """Format instructions as numbered steps"""
        # Split text into sentences and create numbered steps
        sentences = [s.strip() for s in text.replace('.', '.\n').split('\n') if s.strip()]
        
        instructions = []
        for i, sentence in enumerate(sentences[:8], 1):  # Limit to 8 steps
            if len(sentence) > 10:  # Skip very short fragments
                instructions.append(f"{i}. {sentence}")
        
        return '\n'.join(instructions) if instructions else "1. Follow standard cooking methods for the ingredients provided."
    
    def _create_fallback_recipe(self, ingredients: str) -> str:
        """Create a basic fallback recipe when generation fails"""
        return f"""### Recipe Title:
Simple {ingredients.replace(',', ' and')} Dish

### Description:
A straightforward recipe using the provided ingredients.

### Ingredients:
{self._format_ingredients(ingredients)}
- Salt and pepper to taste
- 2 tbsp cooking oil

### Instructions:
1. Prepare all ingredients by washing and chopping as needed.
2. Heat oil in a large pan over medium heat.
3. Add ingredients in order of cooking time required.
4. Season with salt and pepper.
5. Cook until all ingredients are properly prepared.
6. Serve hot.

### Prep Time:
10 minutes

### Cook Time:
20 minutes

### Total Time:
30 minutes

### Servings:
2-4

### Chef's Tips:
- Adjust seasoning to taste
- Cook ingredients until properly done"""

# For backward compatibility with existing code
class T5ModelHandler(EnhancedT5RecipeHandler):
    """Backward compatible wrapper"""
    
    def generate(self, input_text: str, max_length: int = 512, temperature: float = 0.7) -> str:
        """Original generate method that now uses enhanced prompting"""
        # Extract just the ingredients part if it's in the old format
        if input_text.startswith("generate recipe:"):
            ingredients = input_text.replace("generate recipe:", "").strip()
        else:
            ingredients = input_text
        
        return self.generate_recipe_with_structured_prompt(ingredients, max_length, temperature)