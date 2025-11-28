import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    labels: Array,
    datasetNames: Object,
    datasets: Object,
    colorsLightTheme: Array,
    colorsDarkTheme: Array,
    unit: String
  }
  static targets = ["chart", "checkbox"]

  connect() {
    this.visibleDatasets = new Set()
    // Initialize all datasets as visible
    Object.keys(this.datasetsValue).forEach(key => {
      this.visibleDatasets.add(key)
    })
    this.createChart()
    this.observeThemeChanges()
    this.handleResize()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }

    if (this.chart) {
      this.chart.destroy()
    }

    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
  }

  toggleDataset(event) {
    const fieldKey = event.target.dataset.fieldKey
    const isChecked = event.target.checked

    if (isChecked) {
      this.visibleDatasets.add(fieldKey)
    } else {
      this.visibleDatasets.delete(fieldKey)
    }

    this.updateChart()
  }

  createChart() {
    const theme = document.documentElement.dataset.frTheme;
    let colors = this.colorsLightThemeValue;
    let axisColor = '#3a3a3a';
    let gridColor = '#3a3a3a59';

    // Destroy previous chart if exists.
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }

    if (theme === 'dark') {
      colors = this.colorsDarkThemeValue;
      axisColor = '#FFFFFF';
      gridColor = '#FFFFFF59';
    }

    const datas = {
      labels: this.labelsValue,
      datasets: this.createDatasets(colors)
    };

    const config = {
      data: datas,
      options: {
        font: {
          family: 'Marianne, Arial, sans-serif'
        },
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false // We use checkboxes instead
          },
          title: {
            display: false,
            text: this.titleValue,
          }
        },
        scales: {
          x: {
            ticks: {
              font: {
                family: 'Marianne, Arial, sans-serif',
                size: 14
              },
              color: axisColor
            },
            grid: {
              color: gridColor
            },
            border: {
              color: axisColor
            },
          },
          y: {
            ticks: {
              font: {
                family: 'Marianne, Arial, sans-serif',
                size: 14
              },
              color: axisColor,
              callback: (value, index, ticks) => {
                if (this.unitValue !== '') {
                  return value + this.unitValue;
                }
                return value;
              }
            },
            grid: {
              color: gridColor
            },
            border: {
              color: axisColor
            },
            beginAtZero: false,
          }
        }
      },
    };

    this.chart = new Chart(this.chartTarget, config);
  }

  createDatasets(colors) {
    const fieldKeys = Array.from(this.visibleDatasets)
    const datasets = []

    fieldKeys.forEach((fieldKey, index) => {
      const dataset = this.datasetsValue[fieldKey]
      const colorIndex = index % colors.length
      const color = colors[colorIndex]

      datasets.push({
        label: this.datasetNamesValue[fieldKey],
        data: dataset,
        borderColor: color,
        backgroundColor: color,
        type: 'line',
        fill: false,
        spanGaps: false, // Break line at null values
        tension: 0.1
      })
    })

    return datasets
  }

  updateChart() {
    if (!this.chart) return

    const theme = document.documentElement.dataset.frTheme;
    let colors = this.colorsLightThemeValue;
    if (theme === 'dark') {
      colors = this.colorsDarkThemeValue;
    }

    this.chart.data.datasets = this.createDatasets(colors)
    this.chart.update()
  }

  updateChartTheme() {
    if (this.chart) {
      this.chart.destroy()
    }

    // Recreate graph.
    this.createChart()
  }

  observeThemeChanges() {
    // Observe theme changes.
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'data-fr-theme') {
          this.updateChartTheme();
        }
      })
    })

    this.observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-fr-theme']
    })
  }

  handleResize() {
    this.resizeHandler = () => {
      if (this.chart) {
        this.chart.resize()
      }
    }
    window.addEventListener('resize', this.resizeHandler)
  }
}

