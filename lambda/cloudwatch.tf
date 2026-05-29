# Cloudwatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_cloudwatch_dashboard ? 1 : 0

  dashboard_name = "lambda-${aws_lambda_function.lambda.id}"
  dashboard_body = jsonencode({
    "start" : "-PT168H",
    "widgets" : [
      {
        "height" : 9,
        "width" : 12,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.lambda.id, { stat : "PR(:1)" }],
            ["...", { stat : "PR(1:1.3)" }],
            ["...", { stat : "PR(1.3:1.69)" }],
            ["...", { stat : "PR(1.69:2.19)" }],
            ["...", { stat : "PR(2.19:2.85)" }],
            ["...", { stat : "PR(2.85:3.7)" }],
            ["...", { stat : "PR(3.7:4.82)" }],
            ["...", { stat : "PR(4.82:6.27)" }],
            ["...", { stat : "PR(6.27:8.15)" }],
            ["...", { stat : "PR(8.15:10.60)" }],
            ["...", { stat : "PR(10.60:13.78)" }],
            ["...", { stat : "PR(17.92:23.29)" }],
            ["...", { stat : "PR(23.29:30.28)" }],
            ["...", { stat : "PR(30.28:39.37)" }],
            ["...", { stat : "PR(39.37:51.18)" }],
            ["...", { stat : "PR(51.18:66.54)" }],
            ["...", { stat : "PR(66.54:86.50)" }],
            ["...", { stat : "PR(86.50:112.45)" }],
            ["...", { stat : "PR(112.45:146.19)" }],
            ["...", { stat : "PR(146.19:190.04)" }],
            ["...", { stat : "PR(190.04:247.06)" }],
            ["..."],
            ["...", { stat : "PR(321.18:)" }]
          ],
          "view" : "bar",
          "stacked" : false,
          "region" : data.aws_region.current.region,
          "stat" : "PR(247.06:321.18)",
          "period" : 900,
          "setPeriodToTimeRange" : true,
          "title" : "Duration Distribution"
        }
      },
      {
        "height" : 3,
        "width" : 6,
        "y" : 0,
        "x" : 18,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.lambda.id, { color : "#d62728" }]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "stacked" : true,
          "region" : data.aws_region.current.region,
          "stat" : "Sum",
          "period" : 900,
          "title" : "",
          "setPeriodToTimeRange" : true,
          "trend" : false
        }
      },
      {
        "height" : 3,
        "width" : 6,
        "y" : 0,
        "x" : 12,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.lambda.id]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "stacked" : true,
          "region" : data.aws_region.current.region,
          "stat" : "Sum",
          "period" : 900,
          "setPeriodToTimeRange" : true,
          "trend" : false,
          "title" : "",
          "legend" : {
            "position" : "right"
          }
        }
      },
      {
        "height" : 9,
        "width" : 24,
        "y" : 9,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [
              "AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.lambda.id,
              { stat : "tm99", yAxis : "right", color : "#9467bd" }
            ],
            [".", "Invocations", ".", ".", { yAxis : "left", color : "#bcbd22" }],
            [".", "Errors", ".", ".", { yAxis : "left", color : "#d62728" }]
          ],
          "sparkline" : true,
          "view" : "timeSeries",
          "stacked" : false,
          "region" : data.aws_region.current.region,
          "stat" : "Sum",
          "period" : 900,
          "setPeriodToTimeRange" : false,
          "trend" : true,
          "legend" : {
            "position" : "bottom"
          },
          "title" : "Duration (TM99) x Invocations x Errors",
          "liveData" : false
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 3,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '/aws/lambda/${aws_lambda_function.lambda.id}' | filter ${var.log_severity_property_name} = 'ERROR'\n| stats count(*) as total by coalesce(${var.log_http_status_code_property_name}, 'unknown')\n| sort ${var.log_http_status_code_property_name} asc",
          "region" : data.aws_region.current.region,
          "stacked" : false,
          "title" : "Error Status Codes",
          "view" : "bar"
        }
      },
      {
        "height" : 9,
        "width" : 12,
        "y" : 18,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '/aws/lambda/${aws_lambda_function.lambda.id}' | fields @message\n| filter errorType = 'error' or ${var.log_severity_property_name} = 'ERROR'\n| sort @timestamp desc",
          "region" : data.aws_region.current.region,
          "title" : "Errors",
          "view" : "table"
        }
      }
    ]
  })
}
