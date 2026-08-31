variable "project_name" {
  type = string
}

variable "shard_count" {
  description = "Number of shards. 1 is plenty for testing (up to 1MB/sec or 1000 records/sec in)."
  type        = number
  default     = 1
}
