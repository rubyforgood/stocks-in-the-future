import { Controller } from "@hotwired/stimulus"

// Chart.js needs concrete colour values, so read them from the token layer at
// runtime rather than hard-coding hex here. The points were #4F46E5 (indigo-600)
// while every other accent in the app is sitf-primary, and the line and axes
// were pure black rather than the slate used everywhere else.
function token(name, fallback) {
  const value = getComputedStyle(document.documentElement).getPropertyValue(name)
  return value.trim() || fallback
}

export default class extends Controller {
  static values = {
    data: Array
  }

  async connect() {
    await this.initializeChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  async initializeChart() {
    // Import Chart.js and wait for it to load
    const chartModule = await import("chart.js")

    // Access Chart from the imported module - try multiple possible export patterns
    const Chart = chartModule.default || chartModule.Chart || window.Chart

    if (!Chart) {
      console.error("Chart.js not loaded properly")
      return
    }

    const ctx = this.element.getContext("2d")

    // Extract labels and data from chartData
    const labels = this.dataValue.map(point => point.label)
    const values = this.dataValue.map(point => point.value)

    this.chart = new Chart(ctx, {
        type: "line",
        data: {
          labels: labels,
          datasets: [{
            label: "Portfolio value",
            data: values,
            borderColor: token("--sitf-primary-chart1", "#00698c"),
            backgroundColor: "rgba(0, 105, 140, 0.10)",
            borderWidth: 2.5,
            pointRadius: 6,
            pointBackgroundColor: token("--sitf-primary-chart1", "#00698c"),
            pointBorderColor: token("--sitf-primary-chart1", "#00698c"),
            pointBorderWidth: 0,
            pointHoverRadius: 8,
            tension: 0.4,
            fill: false
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          layout: {
            padding: {
              top: 5,
              right: 5,
              bottom: 2,
              left: 2
            }
          },
          plugins: {
            legend: {
              display: false
            },
            tooltip: {
              backgroundColor: "rgba(0, 0, 0, 0.8)",
              padding: 12,
              titleFont: {
                size: 14,
                family: "Inter, sans-serif"
              },
              bodyFont: {
                size: 13,
                family: "Inter, sans-serif"
              },
              callbacks: {
                label: function(context) {
                  return "Value: $" + context.parsed.y.toFixed(2)
                }
              }
            }
          },
          scales: {
            x: {
              grid: {
                display: false
              },
              ticks: {
                font: {
                  size: 12,
                  family: "'Open Sans', system-ui, sans-serif"
                },
                color: "#334155",
                padding: 3
              },
              border: {
                display: false
              },
              offset: true
            },
            y: {
              grid: {
                display: true,
                color: "rgba(51, 65, 85, 0.12)",
                drawBorder: false
              },
              ticks: {
                font: {
                  size: 12,
                  family: "'Open Sans', system-ui, sans-serif"
                },
                color: "#334155",
                padding: 4,
                callback: function(value) {
                  return "$" + value.toFixed(0)
                }
              },
              border: {
                display: false
              },
              grace: '2%'
            }
          }
        }
      })
  }
}
