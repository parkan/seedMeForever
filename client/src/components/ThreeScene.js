import React, { Component } from 'react';
import * as THREE from 'three';
import smoke from '../assets/Smoke-Element.png';
import { apiUrl } from './../env';

class ThreeScene extends Component{
  componentDidMount(){
    const width = this.mount.clientWidth
    const height = this.mount.clientHeight
    this.width = width;
    this.height = height;

    this.highestArchive = 1;
    this.maxDisplays = 6;

    this.scene = new THREE.Scene()

    this.camera = new THREE.PerspectiveCamera(
      75,
      width / height,
      0.1,
      1000
    )
    this.camera.position.z = 1000

    this.renderer = new THREE.WebGLRenderer({ antialias: true })
    this.renderer.setClearColor('#ffffff')
    this.renderer.setSize(width, height)
    this.mount.appendChild(this.renderer.domElement)

    this.clock = new THREE.Clock();

    const light = new THREE.DirectionalLight(0xffffff,1);
    light.position.set(-1,0,1);
    this.scene.add(light);

    this.smokeParticles = [];
    this.animals = []

    this.smokeTexture = new THREE.TextureLoader().load(smoke);
    this.smokeMaterial = new THREE.MeshLambertMaterial({color: 0xd3dbe8, map: this.smokeTexture, transparent: true});
    this.planeGeo = new THREE.PlaneGeometry(300, 300);

    this.createSmoke();
    this.createAnimal();

    this.start()
  }

  createSmoke() {
    for (let p = 0; p < 100; p++) {
      var particle = new THREE.Mesh(this.planeGeo, this.smokeMaterial);
      particle.position.set(Math.random()*500-250, Math.random()*500-250, Math.random()*1000-100);
      particle.rotation.z = Math.random() * 360;
      this.scene.add(particle);
      this.smokeParticles.push(particle);
    }
  }

  random(min, max) {
    var x = Math.abs(Math.sin(Math.random()));
    return Math.floor(x * (max - min) + min);
  }

  getRand() {
    const rand = Math.floor(Math.random() * (this.highestArchive - 1 + 1)) + 1;
    // console.log(rand)
    return rand;
  }

  getMax() {
    return fetch(`${apiUrl}/archive/max`, {
    method: "GET",
    headers: {
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    }})
      .then(response => {
        // console.log(response)
        return response.json()
      })
  }

  async createAnimal(id) {
    let pic;
    THREE.ImageUtils.crossOrigin = '';
    const picTexture = new THREE.TextureLoader().load(`${apiUrl}/archive/${id}`, (tex) => {
      tex.needsUpdate = true;
      pic.scale.set(1.0, tex.image.height / tex.image.width, 1.0);
    });
    const picMaterial = new THREE.MeshLambertMaterial({color: 0xbbffff, opacity: 1, map: picTexture, transparent: true, blending: THREE.AdditiveBlending})
    pic = new THREE.Mesh(this.planeGeo, picMaterial);
    pic.position.z = 800;
    var randx = this.random((this.width/6) * -1, this.width/6);
    var randy = this.random((this.height/6) * -1, this.height/6);
    pic.position.x = randx;
    pic.position.y = randy;
    this.animals.push({ mesh: pic, opacity: .0001, lastOpacity: 0 })
    this.scene.add(pic);
  }

  evolveSmoke() {
    var sp = this.smokeParticles.length;
    while(sp--) {
      this.smokeParticles[sp].rotation.z += (this.delta * 0.2);
    }
  }

  fadeAnimals() {
    let sp = this.animals.length;
    while(sp--) {
      const animal = this.animals[sp];
      if (animal.opacity >= 1) {
        animal.lastOpacity = 1
        animal.opacity = 0.99
      } else if (animal.opacity <= 0) {
        this.scene.remove( animal );
        // console.log(animal.mesh.material)
        animal.mesh.material.map.dispose();
        animal.mesh.material.dispose();
        animal.mesh.geometry.dispose();
        this.animals.splice(sp, 1)
        break;
      } else if (animal.opacity > animal.lastOpacity
          || animal.opacity === animal.lastOpacity
        ) {
        animal.lastOpacity = animal.opacity;
        animal.opacity += (this.delta * 0.2);
      } else {
        animal.lastOpacity = animal.opacity;
        animal.opacity -= (this.delta * 0.2);
      }
      animal.mesh.material.opacity = animal.opacity
    }
  }

  componentWillUnmount(){
    this.stop()
    this.mount.removeChild(this.renderer.domElement)
  }

  start = () => {
    if (!this.frameId) {
      this.frameId = requestAnimationFrame(this.animate)
    }
  }

  stop = () => {
    cancelAnimationFrame(this.frameId)
  }

  animate = async () => {
    // note: three.js includes requestAnimationFrame shim
    this.delta = this.clock.getDelta();
    requestAnimationFrame( this.animate );
    this.evolveSmoke();
    this.fadeAnimals();
    if (Math.floor(Math.random() * 100) % 200 === 0) {
      const max = await this.getMax();
      if (max > this.highestArchive) { 
        this.createAnimal(max);
        this.highestArchive = max;
        this.maxDisplays = 6;
      } else if (this.maxDisplays > 0) {
        this.createAnimal(max);
        this.maxDisplays -= 1;
      } else {
        const id = this.getRand()
        this.createAnimal(id);
      }
    }
    this.renderScene();
 }

  renderScene = () => {
    this.renderer.render(this.scene, this.camera)
  }

  render(){
    return(
      <div
        style={{
          width: '100%',
          height: '100%',
          left: "0px",
          marginTop: "-8px",
          position: 'fixed' }}
        ref={(mount) => { this.mount = mount }}
      />
    )
  }
}

export default ThreeScene