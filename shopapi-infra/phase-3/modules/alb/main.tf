# ── Application Load Balancer ─────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.project}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids   # needs 2 subnets in different AZs

  tags = { Name = "${var.project}-${var.env}-alb", Project = var.project }
}

# ── Target Group ──────────────────────────────────────────
# Points to EC2 on port 3000
resource "aws_lb_target_group" "app" {
  name     = "${var.project}-${var.env}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "3000"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = { Project = var.project }
}

# ── Listener ──────────────────────────────────────────────
# HTTP on port 80 → forward to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
