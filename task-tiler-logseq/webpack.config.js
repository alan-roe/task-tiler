const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
  entry: './main.js',
  output: {
    path: path.resolve(__dirname, './dist'),
    filename: '[name].js',
  },
  optimization: {
    splitChunks: {
      chunks: 'all',
    },
  },
  devServer: {
    compress: true,
    port: 9000,
  },
  plugins:[
    new HtmlWebpackPlugin({
      title: 'Task Tiler Logseq',
      scriptLoading: 'module'
    }),
    new CopyWebpackPlugin({
      patterns: [
        { from: './package.json', to: 'package.json' },
      ],
    })]
};