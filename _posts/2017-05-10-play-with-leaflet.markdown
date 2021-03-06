---
layout: post
title:  Leaflet 使用及开发
link:  play-with-leaflet
date:   2017-05-10 17:33:00 +0800
categories: javascript
---

[`Leaflet`](http://leafletjs.com/) 是一个开源的地图交互框架。这篇文章记录在配合 webpack 接触、使用 leaflet 的过程中的一些要点、心得。

### 引入

首先是安装依赖：

```bash
npm install --save leaflet
```

然后在项目中正常通过 `require('leaflet')` 引入。一旦引入，leaflet 会在 `window` 下注册全局变量 `L` 指向模块自身, 因此在之后的代码里可以随意使用 `L` 来访问 leaflet 的功能。不过如果配置了 eslint，
可能需要在 `eslintrc.js` 文件里为此全局变量做声明，免得报错，具体可以参考上一篇文章。

### 基本使用

Leaflet 的框架程序风格很赞。在 `L` 对象之下的各种大写字母开头的属性基本上都是各种模块的构造函数，与之对应的，每个模块基本上都有 `camelCase` 命名风格的函数式方法，会返回此模块的一个新的实例，省去了使用 关键字 `new`。 例如：

```javascript
var mapA = L.map(elA, {
  center: [32, 120],
  zoom: 10
})

var mapB = new L.Map(elB, {
  center: [32, 120],
  zoom: 10
})

```

两种写法，从功能上是完全一致的。在 leaflet 官网的例子里以及很多插件里都遵循、实现了这个特性。

### 瓦片图供应商

Leaflet 并不持有任何的地图数据（瓦面图）资源。在地图中，按照坐标位置提供不同尺寸的图片资源的提供者在 leaflet 里又叫做瓦片图供应商。可以通过插件 [Leaflet.ChineseTmsProviders](https://github.com/htoooth/Leaflet.ChineseTmsProviders) 获取到多种国内的瓦面图供应商。使用起来也很简单，先调用 `L.tileLayer` 生成瓦面图层，再添加到地图实例中：

```javascript
var normalTile = L.tileLayer.chinaProvider('GaoDe.Normal.Map', {
  minZoom: 5,
  maxZoom: 18
})

map.addLayer(normalTile)
```

以下是使用 [`Control.Layers`](http://leafletjs.com/reference-1.0.3.html#control-layers) 罗列出所有在 `ChineseTmsProviders` 里提供的瓦面供应商列表并且添加到地图实例上作为切换控件的方法：

```javascript
var config = {
  minZoom: 5,
  maxZoom: 18
}

var p = L.TileLayer.ChinaProvider.providers
var layers = {}
Object.keys(p).forEach(key => {
  var value = p[key]
  Object.keys(value).forEach(ckey => {
    if (ckey !== 'Subdomains') {
      var cvalue = value[ckey]
      Object.keys(cvalue).forEach(cckey => {
        var fullname = `${key}.${ckey}.${cckey}`
        layers[fullname] = L.tileLayer.chinaProvider(fullname, config)
      })
    }
  })
})

//  图层选择控件加入到地图实例
L.control.layers(layers).addTo(map)
//  设置地图默认的使用的层
layers['GaoDe.Normal.Map'].addTo(map)
```

### UI 功能

Leaflet 内置了一些基础 UI，这些 UI 引用了内置的图片资源。在 webpack 环境下使用，由于 loader 设定的图片资料路径的问题，导致可能出现图片路径不正确。可以通过以下方式自定义图片路径：

```javascript
// 解决webpack图片引入的问题
L.Icon.Default.imagePath = '.'
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet-draw/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png')
})
```

#### Marker

marker 是在地图上标注一个点：

```javascript
var marker = L.marker([32, 120]).addTo(map)
```

#### Popup

以下结合地图上的点击事件，在点击处弹出提示，指示点击的坐标：

```javascript
var popup = L.popup()
map.on('click', e => {
  popup.setLatLng(e.latlng)
    .setContent(`You clicked at ${e.latlng.toString()}`)
    .openOn(map)
})
```

#### Tooltip

用来在地图上的一些层（例如各种控件，marker等等）上展示小段的辅助文本信息:

```javascript
marker.bindTooltip('Here is The Place!').openTooltip()
```

### 基本矢量图形绘制

以下是在地图上绘制形状的基本方法。其中，圆形使用 `svg` 渲染, 多边形使用 `canvas` 渲染：

```javascript
marker.bindTooltip('my tooltip text').openTooltip()
var svgRenderer = L.svg({padding: 0.5})

//  创建一个圆图层
var circle = L.circle([32, 120], {
  color: 'red',
  fillColor: '#f03',
  fillOpacity: 0.2,
  radius: 3000,
  renderer: svgRenderer
}).addTo(map)

var canvasRenderer = L.canvas({padding: 0.5})
//  创建多边形
var polygon = L.polygon([
  [31.5, 120],
  [32, 120.5],
  [31.5, 120.3]
], {
  color: 'blue',
  fill: '#f03',
  fillOpacity: 0.2,
  renderer: canvasRenderer
}).addTo(map)

polygon.bindPopup('THE RESTRICTED AREA!')
setTimeout(() => {
  polygon.openPopup()
}, 1000)
setTimeout(() => {
  polygon.closePopup()
}, 3000)

//  zoom the map to the polygon
map.fitBounds(polygon.getBounds())
```

### 层级容器／组

LayerGroup` 相当于是一个容器层，在其中可以装载多个其他 `Layer`，作为一个整体操作；`FeatureGroup` 相当于是一个威力加强版的 `LayerGroup`， 区别在于：对这个容器组操作(例如 `bindPopup`)可以对其中的每一个子层级生效，以及响应子层级冒泡传递过来的事件:

```javascript
L.featureGroup([circle, polygon, marker])
  .bindPopup('Hi There...')
  .on('click', e => {
    alert('you click the feature-group...')
  })
  .addTo(map)
```

### [`Leaflet.Draw`](https://github.com/Leaflet/Leaflet.draw)

通过以上的例子，如果要在地图上操作绘制一些几何图形，是需要自己实现的取点、绘制等操作的。可以通过插件 `Leaflet.Draw` 帮我们完成这个工作。使用起来也不复杂：

首先添加编辑控件栏。可以通过 `L.drawLocal` 设置语言文本等属性，此处也设置了一些控件构造参数：

```javascript
var drawItems = L.featureGroup()
map.addLayer(drawItems)
var drawControl = new L.Control.Draw({
  edit: {
    featureGroup: drawItems
  },
  draw: {
    polygon: {
      allowIntersection: true,
      drawError: {
        color: '#f00000',
        message: `<strong>Oh snap!</strong> you can't draw that!`
      },
      shapeOptions: {
        color: '#bada55',
        opacity: 0.1
      }
    }
  }
})
map.addControl(drawControl)
```

添加了控件之后，就可以点击地图上的控件直接在地图上绘制图形。插件也提供了一些事件使得我们可以处理绘制时产生的数据。详细的事件列表可见于 [官方文档](https://leaflet.github.io/Leaflet.draw/docs/leaflet-draw-latest.html#l-draw-feature)。

以下例子里，通过 [`GeoJSON`](http://leafletjs.com/examples/geojson/) 和 `localStorage` 实现了基本的保存/读取绘制的多变形的功能：

```javascript
var drawItems = L.featureGroup()
var drawGeoJson = localStorage.getItem('drawLayers')
try {
  drawGeoJson = JSON.parse(drawGeoJson)
} catch (e) {
  //  not found
}
if (typeof drawGeoJson === 'object') {
  drawItems = L.geoJSON(drawGeoJson, {
    style: {
      color: '#bada55',
      opacity: 0.9
    }
  }).eachLayer(layer => {
    drawItems.addLayer(layer)
  })
}

...

//  save after created
map.on(L.Draw.Event.CREATED, e => {
  var type = e.layerType
  var layer = e.layer
  if (type === 'marker') {
    // marker
    let latlng = layer.getLatLng()
    layer.bindPopup(`lat = ${latlng.lat}\nlng = ${latlng.lng}`)
  }

  drawItems.addLayer(layer)
  localStorage.setItem('drawLayers', JSON.stringify(drawItems.toGeoJSON()))
})

//  save after edited
map.on('draw:edited', e => {
  localStorage.setItem('drawLayers', JSON.stringify(drawItems.toGeoJSON()))
})

//  save after deleted
map.on('draw:deleted', e => {
  localStorage.setItem('drawLayers', JSON.stringify(drawItems.toGeoJSON()))
})
```

### 总结

通过以上的主要功能点介绍和使用，基本上已经能轻松的使用 `leaflet` 了。如果有需要，可以自行在此基础上开发相关扩展插件。[`leaflet.measure`](https://github.com/aprilandjan/leaflet.measure) 是我在前人的基础上开发的一个测量插件。
