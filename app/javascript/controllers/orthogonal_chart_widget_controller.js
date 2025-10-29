import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    labels: Array,
    datasetNames: Array,
    datasets: Array,
    colorsLightTheme: Array,
    colorsDarkTheme: Array,
    types: Array,
    borderDash: Array,
    order: Array,
    barMode: String,
    unit: String
  }
  static targets = ["chart"]

  connect() {
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

  createChart(data) {
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
      datasets: this.createDatasets()
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
            position: 'bottom',
            labels: {
              font: {
                family: 'Marianne, Arial, sans-serif',
                size: 12
              },
              color: axisColor,
              usePointStyle: true,
              pointStyle: 'circle',
              padding: 35,
              generateLabels: function (chart) {
                const labels = Chart.defaults.plugins.legend.labels.generateLabels(chart);
                labels.forEach(label => {
                  label.lineWidth = 0;
                });
                return labels;
              }
            },
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
            beginAtZero: true,
            stacked: this.barModeValue === 'stacked',
          }
        },
        datasets: {
          bar: {
            grouped: false,
            barPercentage: 1,
            categoryPercentage: 1,
          }
        }
      },
    };

    this.chart = new Chart(this.chartTarget, config);
  }

  createDatasets() {
    const theme = document.documentElement.dataset.frTheme;
    let colors = this.colorsLightThemeValue;
    if (theme === 'dark') {
      colors = this.colorsDarkThemeValue;
    }

    const datasets = this.datasetsValue.map((dataset, index) => {
      const type = this.typesValue[index];

      const baseConfig = {
        label: this.datasetNamesValue[index],
        data: dataset,
        borderColor: colors[index],
        backgroundColor: colors[index],
        order: this.orderValue[index],
      };

      // Specific config for each type.
      if (type === 'line') {
        return {
          ...baseConfig,
          type: 'line',
          fill: 1,
          borderDash: this.borderDashValue[index],
        };
      }

      if (type === 'bar') {
        return {
          ...baseConfig,
          type: 'bar',
          stack: 'combined'
        };
      }

      // Default.
      return {
        ...baseConfig,
        type: 'bar',
        stack: 'combined'
      };
    });

    return datasets
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
