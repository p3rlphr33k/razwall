/*
 * +--------------------------------------------------------------------------+
 * | Endian Firewall                                                          |
 * +--------------------------------------------------------------------------+
 * | Copyright (c) 2004-2017 Endian S.p.A. <info@endian.com>                  |
 * |         Endian S.p.A.                                                    |
 * |         via Pillhof 47                                                   |
 * |         39057 Appiano (BZ)                                               |
 * |         Italy                                                            |
 * |                                                                          |
 * | This program is proprietary software; you are not allowed to             |
 * | redistribute and/or modify it.                                           |
 * | This program is distributed in the hope that it will be useful,          |
 * | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
 * | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     |
 * +--------------------------------------------------------------------------+
 */

/*Class used to build a tree of checkbox inputs*/
function Node(value) {

    this.name = value;
    this.children = [];
    this.parent = null;
    this.layers = [];
    this.path = 'root';
    this.input = null;
    
    this.setParentNode = function(node) {
        this.parent = node;
    }

    this.getParentNode = function() {
        return this.parent;
    }

    this.addChild = function(node) {
        node.setParentNode(this);
        node.setParentNode(this);
        node.path = this.path+'/'+node.name;
        this.children[this.children.length] = node;
    }

    this.getChildren = function() {
        return this.children;
    }

    this.removeChildren = function() {
        this.children = [];
    }

    this.addBranch = function(index, levels, layers){
        var branch = new Node(levels[index]);
        this.addChild(branch);
        var leaf = null;
        if(index<levels.length-1){
            for(var j=index+1;j<levels.length;j++){
                leaf = new Node(levels[j]);
                branch.addChild(leaf);
                branch = leaf;
            }
            leaf.layers.push(layers);
        }else{
            branch.layers.push(layers);
        } 
    }

    this.hasChild = function(name){
        result = false;
        this.children.forEach(function(child){
            if(child.name == name)
                result = true;
        });
        return result;
    }
}
