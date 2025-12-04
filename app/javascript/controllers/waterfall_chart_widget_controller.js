import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    colorsLightTheme: Array,
    colorsDarkTheme: Array,
    title: String,
    unit: String,
    labels: Array,
    values: Array,
    seuils: Array,
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

    let backgroundColors = []

    this.valuesValue.forEach((values, index) => {
      if (index === this.valuesValue.length - 1) {
        backgroundColors.push(colors[2]);
      } else {
        const val1 = values[0];
        const val2 = values[1];

        if (val2 - val1 < 0) {
          backgroundColors.push(colors[1]);
        } else {
          backgroundColors.push(colors[0]);
        }
      }
    });

    const data = {
      labels: this.labelsValue,
      datasets: [
        {
          data: this.valuesValue,
          backgroundColor: backgroundColors,
        },
      ]
    };

    // Colored background on the last bar.
    const backgroundPlugin = {
      id: 'customBackground',
      beforeDatasetsDraw: (chart) => {
        const {ctx, chartArea: {left, right, top, bottom, width, height}} = chart;

        const lastBarIndex = data.labels.length - 1;
        const meta = chart.getDatasetMeta(0);
        const bar = meta.data[lastBarIndex];

        const categoryWidth = width / data.labels.length;
        const columnLeft = bar.x - categoryWidth / 2;
        const columnWidth = categoryWidth;

        ctx.save();

        ctx.fillStyle = '#b8fec9'; // success-950
        const greenHeight = (this.seuilsValue[0] / 100) * height;
        ctx.fillRect(columnLeft, bottom - greenHeight, columnWidth, greenHeight);

        ctx.fillStyle = '#fceeac'; // green-tilleul-verveine-950
        const yellowHeight = ((this.seuilsValue[1] - this.seuilsValue[0]) / 100) * height;
        ctx.fillRect(columnLeft, bottom - greenHeight - yellowHeight, columnWidth, yellowHeight);

        ctx.fillStyle = '#ffdddd'; // error-925
        const redHeight = ((100 - this.seuilsValue[1]) / 100) * height;
        ctx.fillRect(columnLeft, bottom - greenHeight - yellowHeight - redHeight, columnWidth, redHeight);

        ctx.restore();
      }
    };

    // Add percentage on top of each bar.
    const dataLabelsPlugin = {
      id: 'dataLabels',
      afterDatasetsDraw: (chart) => {
        const {ctx, data} = chart;
        const meta = chart.getDatasetMeta(0);

        const theme = document.documentElement.dataset.frTheme;
        let color = '#000000';

        if (theme === 'dark') {
          color = '#ffffff';
        }

        ctx.save();
        ctx.font = 'bold 12px "Marianne", Arial, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'bottom';

        meta.data.forEach((bar, index) => {
          const dataValue = data.datasets[0].data[index];
          const value = Array.isArray(dataValue) ? dataValue[1] - dataValue[0] : dataValue;
          const label = Math.round(value * 10) / 10 + '%';

          // Changer la couleur pour le dernier label
          if (index === meta.data.length - 1) {
            ctx.fillStyle = '#000000'; // Rouge pour la dernière valeur (change selon tes besoins)
          } else {
            ctx.fillStyle = color;
          }

          ctx.fillText(label, bar.x, bar.y - 5);
        });

        ctx.restore();
      }
    };

    const config = {
      type: 'bar',
      data: data,
      options: {
        font: {
          family: 'Marianne, Arial, sans-serif'
        },
        responsive: true,
        maintainAspectRatio: false,
        layout: {
          padding: {
            top: 30  // Ajoute le padding en haut
          }
        },
        plugins: {
          legend: {
            display: false
          },
          title: {
            display: false,
            text: this.titleValue,
          },
          tooltip: {
            enabled: false
          }
        },
        scales: {
          x: {
            ticks: {
              maxRotation: 0,
              minRotation: 0,
              autoSkip: false,
              padding: 10,
              font: {
                family: 'Marianne, Arial, sans-serif',
                size: 14
              },
              color: axisColor,
              // Display multiple lines for long labels.
              callback: function(value, index) {
                const label = this.getLabelForValue(value);
                const maxWidth = 20;
                const words = label.split(' ');
                const lines = [];
                let currentLine = '';

                words.forEach(word => {
                  const testLine = currentLine + (currentLine ? ' ' : '') + word;
                  if (testLine.length > maxWidth && currentLine) {
                    lines.push(currentLine);
                    currentLine = word;
                  } else {
                    currentLine = testLine;
                  }
                });
                lines.push(currentLine);

                return lines;
              }
            },
            grid: {
              color: gridColor
            },
            border: {
              color: axisColor
            },
          },
          y: {
            min: 0,
            max: 100,
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
        }
      },
      plugins: [backgroundPlugin, dataLabelsPlugin]
    };

    this.chart = new Chart(this.chartTarget, config);
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