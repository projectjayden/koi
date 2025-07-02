use ort::{ Environment, SessionBuilder, Value };
use tokenizers::Tokenizer;
use ndarray::Array2;

pub async fn input(ingredients: Vec<&str>) -> anyhow::Result<String> {
  let tokenizer = Tokenizer::from_file("my_tokenizer/tokenizer.json")?;
  let format_string = format!("Suggest recipes that can be used with these ingredients: {}", ingredients.join(", "));
  let encoding = tokenizer.encode(format_string, true)?;
  let input_ids = encoding.get_ids();

  let array = Array2::from_shape_vec(
    (1, input_ids.len()),
    input_ids
      .iter()
      .map(|&x| x as i64)
      .collect()
  )?;
  let environment = Environment::builder().build()?;
  let session = SessionBuilder::new(&environment)?.with_model_from_file("my_model.onnx")?;

  let outputs = session.run(vec![Value::from_array(session.allocator(), &array)?])?;
  let output_tensor = outputs[0].try_extract::<ndarray::Array2<i64>>()?;
  let output_ids = output_tensor
    .iter()
    .map(|&x| x as u32)
    .collect();

  let result = tokenizer.decode(output_ids, true)?;
  Ok(result)
}
