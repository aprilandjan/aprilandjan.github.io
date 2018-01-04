---
layout: post
title:  webpack-babel-scss-template-with-multi-entries
date:   2016-09-09 22:53:00 +0800
categories: webpack
---

把之前的单页模版改造了一下, 做成了多页模版, 并且加入了 fontspider & spritesmith

### 项目目录

    -- Project
        |-- src
            |-- assets
                |-- fonts   //  字体文件
                |-- imgs    //  图片资源
                |-- sprites //  需要合并的sprite
                |-- styles  //  公共样式
            |-- common      //  公共JS
            |-- views
                |-- pageA   //  pageA 目录
                    |-- app.js
                    |-- index.html
                |-- pageB   //  pageB 目录
                    |-- app.js
                    |-- index.html
        |-- static          //  静态资源
        |-- buildEntries.js //  提及多页入口
        |-- gulpfile.js     //  gulp 脚本文件
        |-- config.json     //  gulp里的关于upload的一些上传的配置 
        |-- favicon.ico     //  页面 favicon

### buildEntries.js
```javascript
var glob = require('glob');
var path = require('path');

function getEntries(globPath, base) {

    var entries = {
        entry: {},  //  webpack js entry object
        htmlWebpackPluginConfigs: {
            // index: {
            //     filename: './index.html',
            //     template: './src/views/index/index.html',
            //     chunks: ['index']
            // },
        }
    };

    var getJsEntry = function(file) {
        var dirs = file.split('/')
        dirs.pop()
        dirs.push('app.js')
        return dirs.join('/')
    }

    var getName = function(file) {
        var dirs = file.split('/')
        dirs.pop()
        return dirs.pop()
    }

    var filenames = glob.sync(globPath);
    filenames.forEach(function (file) {
        //  ./src/views/about/index.html

        var ext = path.extname(file)
        var name = getName(file)
        var jsEntry = getJsEntry(file)

        entries.entry[name] = jsEntry
        entries.htmlWebpackPluginConfigs[name] = {
            filename: './' + name + '.html',
            template: file,
            chunks: [name]
        }
    });
    return entries;
}

var entries = getEntries('./src/views/**/index.html');
// console.log(entries);

module.exports = entries;
```

### webpack.config.json

```javascript
var path = require('path');
var webpack = require('webpack');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var ExtractTextPlugin = require("extract-text-webpack-plugin");

var env = process.env.NODE_ENV
console.log("================= " +  env + " ==================");

var entries = require('./buildEntries');

module.exports = {
    //  入口文件
    entry: entries.entry,
    //  输入目录
    output: {
        path: path.resolve(__dirname, './dist'),
        publicPath: '/',
        filename: '[name].[hash:7].js',
    },
    //  resolves
    resolve: {
        extensions: ['', '.js'],
        fallback: [path.join(__dirname, './node_modules')],
        alias: {
            'src': path.resolve(__dirname, './src'),
            'components': path.resolve(__dirname, './src/components'),
            'common': path.resolve(__dirname, './src/common'),
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

    plugins: [
        new webpack.DefinePlugin({
            'process.env': {
                NODE_ENV: JSON.stringify(env)
            }
        }),
        new webpack.NoErrorsPlugin(),
        new webpack.optimize.OccurenceOrderPlugin()
    ],

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

var compress = env == 'publish'
switch(env){
    case 'dev':
        module.exports.devtool = '#source-map';
        module.exports.module.loaders = (module.exports.module.loaders || []).concat([
            {
                test: /\.scss$/,
                loader: 'style!css!sass'
            }
        ]);
        module.exports.plugins = (module.exports.plugins || []).concat([
            //  none
        ]);

        for(var key in entries.htmlWebpackPluginConfigs){
            var config = entries.htmlWebpackPluginConfigs[key]
            module.exports.plugins.push(new HtmlWebpackPlugin({
                filename: config.filename,
                template: config.template,
                chunks: config.chunks,
                inject: true
            }))
        }
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
            //  压缩JS
            new webpack.optimize.UglifyJsPlugin({
                compress: {
                    warnings: false
                }
            }),
            new ExtractTextPlugin("[name].[hash:7].css", {allChunks: false})
        ]);

        for(var key in entries.htmlWebpackPluginConfigs){
            var config = entries.htmlWebpackPluginConfigs[key]
            module.exports.plugins.push(new HtmlWebpackPlugin({
                filename: config.filename,
                template: config.template,
                chunks: config.chunks,
                favicon: 'favicon48.ico',
                inject: true,
                minify: {
                    removeComments: compress,
                    collapseWhitespace: compress,
                    removeAttributeQuotes: compress
                }
            }))
        }
        break;
}
```

### gulpfile.js

```javascript
var fs = require('fs')
var path = require('path');
var gulp = require('gulp');
var oss = require('gulp-oss');
var dom = require('gulp-dom');
var clean = require('gulp-clean');
var imagemin = require('gulp-imagemin');
var pngquant = require('imagemin-pngquant');
var tinypng = require('gulp-tinypng')
var runSequence = require('run-sequence');
var webpack = require('gulp-webpack')
var fontSpider = require( 'gulp-font-spider' )
var spritesmith = require('gulp.spritesmith')
var inject = require('gulp-inject-string')


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
    return gulp.src('src/views/**/app.js')
        .pipe(webpack(require('./webpack.config.js')))
        .pipe(gulp.dest('dist/'));
});

//  将想要插入的代码块注入html
gulp.task('insert', function(){
    var insertContent = fs.readFileSync('./insert.js', 'utf8');
    var script = '<script>\n' + insertContent + '\t</script>\n'

    gulp.src('./dist/*.html')
        .pipe(inject.before('<link rel=', script))
        .pipe(gulp.dest('./dist'));
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
        ['insert'],
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

//  font spider
gulp.task('fontextract', function() {
    return gulp.src('./fontspider/index.html')
        .pipe(fontSpider());
});

//  font move
gulp.task('fontmove', function() {
    return gulp.src('./fontspider/fonts/*')
        .pipe(gulp.dest('./src/assets/fonts'))
})

//  font extract workflow
gulp.task('fontspider', function(callback){
    runSequence(
        ['fontextract'],
        ['fontmove'],
        callback
    )
});

//  sprite collect collect
gulp.task('sprite', function() {
    var assetsPath = './src/assets/sprites'
    var spritePath = './src/assets/imgs'
    var scssPath = './src/assets/styles'
    var spriteDark = gulp.src(assetsPath + '/*.png').pipe(spritesmith({
        retinaSrcFilter: assetsPath + '/*_2x.png',
        imgName: 'sprites.png',
        cssName: 'sprites.scss',
        retinaImgName: 'sprites2x.png',
        // cssFormat: 'scss',
        // cssTemplate: './spritesmith-retina-mixins.template.mustache',
        // algorithm: "top-down",
        //    padding: 1,
        imgPath: '../../../assets/imgs/sprites.png',
        retinaImgPath: '../../../assets/imgs/sprites2x.png',
        cssVarMap: function (sprite) {
            sprite.name = 'sprite-' + sprite.name;
        }
    }))
    spriteDark.img
        .pipe(gulp.dest(spritePath));

    spriteDark.css
        .pipe(gulp.dest(scssPath));
});
```

### package.json

所需要用到的包依赖

```javascript
{
  "name": "webpack-babel-template",
  "version": "1.0.0",
  "description": "just test",
  "main": "app.js",
  "scripts": {
    "dev": "cross-env NODE_ENV=dev webpack-dev-server",
    "build": "cross-env NODE_ENV=build gulp build",
    "publish": "cross-env NODE_ENV=publish gulp publish",
    "tinypng": "gulp tinypng",
    "font": "gulp fontspider",
    "sprite": "gulp sprite"
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
  },
  "devDependencies": {
    "glob": "^7.0.6",
    "gulp-inject-string": "^1.1.0",
    "gulp.spritesmith": "^6.2.1"
  }
}
```

### TIPS