use std::path::{ Path, PathBuf };
use std::io::{ self, Write };
use std::fs::{ self, File };

fn collect_rust_files(dir: &Path) -> io::Result<Vec<PathBuf>> {
  let mut rust_files: Vec<PathBuf> = Vec::new();
  for entry in fs::read_dir(dir)? {
    let entry: fs::DirEntry = entry?;
    let path: PathBuf = entry.path();
    if path.is_dir() {
      rust_files.extend(collect_rust_files(&path)?);
    } else if path.extension().map_or(false, |ext| ext == "rs") {
      rust_files.push(path);
    }
  }
  Ok(rust_files)
}

/// Generate markdown documentation for all routes
/// 
/// For documentation for each input field, see the actual file
pub fn main() -> io::Result<()> {
  let dir: &'static str = "./src/routes";
  let output_file: &'static str = "docs.md";

  let mut md_output: File = File::create(output_file)?;
  let rust_files: Vec<PathBuf> = collect_rust_files(Path::new(dir))?;

  for file_path in rust_files {
    let content: String = fs::read_to_string(&file_path)?;
    let lines: Vec<&str> = content.lines().collect();

    let mut i: usize = 0;
    while i < lines.len() {
      if lines[i].contains("#[get(") || lines[i].contains("#[post(") {
        let mut start_index: usize = i;
        while start_index > 0 && !lines[start_index - 1].contains("/// # ") {
          start_index -= 1;
        }

        writeln!(md_output, "### File: `{}`", file_path.display())?;
        for line in &lines[start_index..i] {
          writeln!(md_output, "{}", line.strip_prefix("///").unwrap_or(line))?;
        }
        writeln!(md_output)?;
      }
      i += 1;
    }
  }

  println!("Documentation generated in docs.md");
  Ok(())
}
