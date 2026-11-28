// Chart.js with the moment adapter for its time axes, which the media
// statistics (media/statistics.coffee, a JS response rendered by the server)
// call as globals. Only staff pages load this entrypoint.
import Chart from "chart.js/auto";
import moment from "moment";
import "chartjs-adapter-moment";

Object.assign(window, { Chart, moment });
