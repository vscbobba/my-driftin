resource "aws_s3_bucket" "candiate_start"{
  bucket = "candiate-start"

}
resource "aws_s3_object" "folder1" {
  bucket = aws_s3_bucket.candiate_start.bucket
  key    = "folder1/" # Ending "/" creates a folder-like structure
  source = "/dev/null" # You can use any file as a placeholder
}

resource "aws_s3_object" "folder2" {
  bucket = aws_s3_bucket.candiate_start.bucket
  key    = "folder2/" # Ending "/" creates a folder-like structure
  source = "/dev/null" # You can use any file as a placeholder
}

resource "aws_s3_object" "test" {
  bucket = aws_s3_bucket.candiate_start.bucket

  for_each = fileset("./documents/", "**/*")
  key = "test/${each.value}"
  source = "./documents/${each.value}"
}

resource "aws_s3_object" "script" {
    bucket = aws_s3_bucket.candiate_start.bucket
    key = "script"
    source = "script"
}