resource "aws_route53_zone" "primary" {
  name = "wiz-demo.com"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "mongo" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "mongo.wiz-demo.com"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mongo.private_ip]
}
