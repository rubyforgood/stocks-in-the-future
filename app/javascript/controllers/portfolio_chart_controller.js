import { Controller } from "@hotwired/stimulus"

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
            label: "Portfolio Value",
            data: values,
            borderColor: "#000000",
            backgroundColor: "rgba(0, 0, 0, 0.1)",
            borderWidth: 2.5,
            pointRadius: 6,
            pointBackgroundColor: "#4F46E5",
            pointBorderColor: "#4F46E5",
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
                color: "#000000",
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
                color: "rgba(0, 0, 0, 0.1)",
                drawBorder: false
              },
              ticks: {
                font: {
                  size: 12,
                  family: "'Open Sans', system-ui, sans-serif"
                },
                color: "#000000",
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
