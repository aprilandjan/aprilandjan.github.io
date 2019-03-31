---
layout: post
title:  webpack babel scss template
date:   2016-08-24 20:58:00 +0800
categories: webpack
---

自从习惯了使用 es6 以后, 强烈的需求把各个分离的小功能放在不同的文件内, 需要的时候 import 进来, 然后又能自动处理互相的依赖注入关系, 最终便捷的打包发布。于是整理了一份 webpack 配置, 使用 babel/scss

## Updates

2016/9/1: 根据实际项目修正了一些配置错误。添加 gulpfile 用来处理包括 dev/build/publish/upload 等前前后后的问题

## 项目目录

    -- Project
        |-- css
            |-- style.scss      //  css 入口
        |-- src
            |-- app.js      //  js 入口
        |-- static          //  图片等静态资源
        |-- index.html      //  html 入口
        |-- gulpfile.js     //  gulp 脚本文件
        |-- config.json     //  gulp里的关于upload的一些上传的配置
        |-- favicon.ico     //  页面 favicon

## webpack.config.json

```javascript
var path = require('path');
var webpack = require('webpack');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var ExtractTextPlugin = require("extract-text-webpack-plugin");

module.exports = {
    //  入口文件
    entry: './src/app.js',
    //  输入目录
    output: {
        path: path.resolve(__dirname, './dist'),
        publicPath: '/',
        filename: 'bundle.[hash:7].js'
    },
    //  resolves
    resolve: {
        extensions: ['', '.js'],
        fallback: [path.join(__dirname, './node_modules')],
        alias: {
            'src': path.resolve(__dirname, './src'),
            'components': path.resolve(__dirname, './src/components'),
            'static': path.resolve(__dirname, './static')
        }
    },
    resolveLoader: {
        fallback: [path.join(__dirname, './node_modules')]
    },
    module: {
        loaders: [
            {
                test: /\.js$/,
                exclude: /node_modules|libs/,
                loader: 'babel'
            },
            {
                test: /\.html$/,
                loader: 'html',
                query: {
                    minimize: false
                }
            },
            {
                test: /\.(png|jpe?g|gif|svg)(\?.*)?$/,
                loader: 'url',
                query: {
                    limit: 10000,
                    name: 'static/[name].[hash:7].[ext]' //  导出目录
                }
            },
            {
                test: /\.(ico)(\?.*)?$/,
                loader: 'file',
                query: {
                    name: 'static/[name].[hash:7].[ext]' //  导出目录
                }
            },
            {
                test: /\.json$/,
                loader: 'json'
            }
        ]
    },

    //  babel编译需要
    babel: {
        presets: ['es2015'],
        plugins: ['transform-runtime']
    },

    //  devServer需要
    devServer: {
        historyApiFallback: true,
        hot: false,     //  不需要实时更新，禁用
        // contentBase: './',  //   内容的基本路径
        host: '0.0.0.0',  //  添加之后可以外部访问
        // noInfo:true,    //  去掉编译过程中的输出信息
        // lazy: true     //   no watching, compile on request
    }
};

console.log("================= " +  process.env.NODE_ENV + " ==================");
var compress = process.env.NODE_ENV == 'publish'
switch(process.env.NODE_ENV){
    case 'dev':
        module.exports.devtool = '#source-map';
        module.exports.module.loaders = (module.exports.module.loaders || []).concat([
            {
                test: /\.scss$/,
                loader: 'style!css!sass'
            }
        ]);
        module.exports.plugins = (module.exports.plugins || []).concat([
            new webpack.optimize.OccurenceOrderPlugin(),
            new webpack.NoErrorsPlugin(),
            new HtmlWebpackPlugin({
                filename: 'index.html',
                template: 'index.html',
                inject: true
            }),
        ]);
        break;
    case 'build':
    case 'publish':
        module.exports.output.publicPath = '//your_public_path_here/';
        module.exports.module.loaders = (module.exports.module.loaders || []).concat([
            {
                test: /\.scss$/,
                loader: ExtractTextPlugin.extract(
                    'style', // backup loader when not building .css file
                    'css!sass' // loaders to preprocess CSS
                )
            }
        ]);
        module.exports.plugins = (module.exports.plugins || []).concat([
            //  定义环境变量
            new webpack.DefinePlugin({
                'process.env': {
                    NODE_ENV: '"production"'
                }
            }),
            //  压缩JS
            new webpack.optimize.UglifyJsPlugin({
                compress: {
                    warnings: false
                }
            }),
            //  注入HTML
            new webpack.optimize.OccurenceOrderPlugin(),
            new ExtractTextPlugin("style.[hash:7].css", {allChunks: true}),
            new HtmlWebpackPlugin({
                filename: 'index.html',
                template: 'index.html',
                favicon: 'favicon48.ico',
                inject: true,
                minify: {
                    removeComments: compress,
                    collapseWhitespace: compress,
                    removeAttributeQuotes: compress
                }
            })
        ]);
        break;
}
```

## gulpfile.js

```javascript
var path = require('path');
var gulp = require('gulp');
var oss = require('gulp-oss');
// var dom = require('gulp-dom');
var clean = require('gulp-clean');
var imagemin = require('gulp-imagemin');
var pngquant = require('imagemin-pngquant');
var tinypng = require('gulp-tinypng')
var runSequence = require('run-sequence');
var webpack = require('gulp-webpack')

var config = require('./config.json');

var publishDir = 'dist';
var publishPath = path.join(__dirname, publishDir);

//  clear directory
gulp.task('clean', function() {
    return gulp.src(publishDir)
        .pipe(clean({read: false}));
})

//  webpack
gulp.task('webpack', function() {
    return gulp.src('src/entry.js')
        .pipe(webpack(require('./webpack.config.js')))
        .pipe(gulp.dest('dist/'));
});

//  上传资源
gulp.task('upload-cdn', function(){
    var ossConfig = config.oss;
    ossConfig.prefix += (config.project + '/')

    return gulp.src([publishPath + "/**/*", "!" + publishPath + "/**/*.html", "!" + publishPath + "/rev-manifest.json"])
        .pipe(oss(ossConfig, {
            // gzippedOnly: true,
            headers: {
                Bucket: ossConfig.bucket,
                CacheControl: 'max-age=315360000',
                ContentDisposition: '',
                Expires: new Date().getTime() + 365 * 24 * 60 * 60 * 1000
            },
            uploadPath: ossConfig.prefix
        }));
});

//  压缩图片等资源
gulp.task("minify-image", function(){
    return gulp.src([publishPath + "/**/*.jpg", publishPath + "/**/*.png"])
        .pipe(imagemin({
            progressive:true,
            use:[pngquant({quality: '65-80', speed: 4})]
        }))
        .pipe(gulp.dest(path.join(publishPath)));
});

//  tinypng
gulp.task('tinypng', function() {
    return gulp.src('static/**/*.png')
        .pipe(tinypng(config.tinypng.key))
        .pipe(gulp.dest('static'))
})

//  仅发布
gulp.task('build', function(callback){
    runSequence(
        ['clean'],
        ['webpack'],
        callback
    )
});

//  发布、压缩图片、上传CDN
gulp.task('publish', function(callback){
    runSequence(
        ['build'],
        ['minify-image'],
        ['upload-cdn'],
        callback
    )
});
```

## package.json

所需要用到的包依赖

```json
{
  "name": "webpack-babel-template",
  "version": "1.0.0",
  "description": "just test",
  "main": "app.js",
  "scripts": {
    "dev": "cross-env NODE_ENV=dev webpack-dev-server",
    "build": "cross-env NODE_ENV=build gulp build",
    "publish": "cross-env NODE_ENV=publish gulp publish",
    "tinypng": "gulp tinypng"
  },
  "author": "aprilandjan",
  "license": "ISC",
  "dependencies": {
    "babel-core": "^6.0.0",
    "babel-loader": "^6.0.0",
    "babel-plugin-transform-runtime": "^6.0.0",
    "babel-preset-es2015": "^6.0.0",
    "babel-preset-stage-2": "^6.0.0",
    "babel-runtime": "^6.0.0",
    "cross-env": "^2.0.0",
    "css-loader": "^0.21.0",
    "extract-text-webpack-plugin": "^1.0.1",
    "file-loader": "^0.8.5",
    "gulp": "^3.9.1",
    "gulp-clean": "^0.3.2",
    "gulp-dom": "^0.9.0",
    "gulp-imagemin": "^3.0.3",
    "gulp-oss": "^0.1.1",
    "gulp-tinypng": "^1.0.2",
    "gulp-webpack": "^1.5.0",
    "html-loader": "^0.4.3",
    "html-webpack-plugin": "^2.22.0",
    "imagemin-pngquant": "^5.0.0",
    "json-loader": "^0.5.4",
    "node-sass": "^3.4.2",
    "run-sequence": "^1.2.2",
    "sass-loader": "^3.2.3",
    "style-loader": "^0.13.1",
    "url-loader": "^0.5.7",
    "webpack": "^1.13.2",
    "webpack-dev-server": "^1.14.1"
  }
}
```

## TIPS

- 在 npm script 里使用 `NODE_ENV=dev` 注入命令进程的环境变量；
- 在 `webpack.config.json` 里通过 `process.env.NODE_ENV` 获取注入的环境变量；
- 在 `webpack.config.json` 里使用 `webpack.DefinePlugin` 定义注入到 bundle.js 里的环境变量；
- 在 bundle.js 里直接访问以上环境变量并做相应的配置；
- 在 `webpack.HtmlWebpackPlugin` 里可以通过字段 `favicon` 配置注入页面 favicon。