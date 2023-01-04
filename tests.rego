package main

deny[msg] {
	proto := input.resource.github_repository["fred_three"].default_branch
	msg = sprintf("repoi `%v` is using wrong default branch", ["fred_three"])
}

deny[msg] {
  input.kind == "github_repository"
  not input.spec.selector.matchLabels.app

  msg := "Containers must provide app label for pod selectors"
}


deny[msg] {
	proto := input.resource_changes.github_repository[gh].default_branch
	proto == "main"
	msg = sprintf("ALB `%v` is using HTTP rather than HTTPS", [gh])
}

test_foo {
  input := {
    "abc": 123,
    "foo": ["bar", "baz"],
  }
  deny with input as input
}       