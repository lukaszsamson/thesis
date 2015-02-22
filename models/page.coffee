
mongoose = require 'mongoose'
Schema = mongoose.Schema
Link = require './link'
Like = require './like'
Transforms = require('../models/query')

PageSchema = new Schema
  facebookId: String
  updatedDate: Date
  name: String
  category: String
  links: [Link.schema]
  linksUpdatedDate: Date
  likes: [Like.schema]
  likesUpdatedDate: Date

PageSchema.statics.saveOrUpdate = (pageData, done) ->
  this.findOne({
    facebookId: pageData.id
  }, (error, page) ->
    return done(error) if error
    if not page
      new Page(
        name: pageData.name
        category: pageData.category
        facebookId: pageData.id
        createdDate: new Date
        updatedDate: new Date
      ).save done
    else
      page.name = pageData.name
      page.category = pageData.category
      page.updatedDate = new Date
      page.save(done)
  )

  
  
PageSchema.statics.updateLinks = (pageId, links, done) ->
  this.update({
      facebookId: pageId
    }, {
      $set: {
        linksUpdatedDate: new Date
        links: links.map((link) ->
          new Link(
            link: link.link
            facebookId: link.id
            name: link.name ? ''
            message: link.message ? ''
            created_time: new Date(Date.parse(link.created_time))
          )
        )
      }
    }, {
      multi: false
    }, done)
    

PageSchema.statics.updateLikes = (pageId, likes, done) ->
  this.update({
      facebookId: pageId
    }, {
      $set: {
        likesUpdatedDate: new Date
        likes: likes.map((like) ->
          new Like(
            facebookId: like.id
            name: like.name ? ''
            category: like.category ? ''
            created_time: new Date(Date.parse(like.created_time))
          )
        )
      }
    }, {
      multi: false
    }, done)

PageSchema.statics.mapReduceResults = (operation, facebookId, callback) ->
  mongoose.connection.db.collection operation, (err, collection) ->
    return callback(err) if err
    collection.findOne {_id: facebookId}, (err, result) ->
      return callback(err) if err
      callback(null, result)

PageSchema.statics.mapReduceRequest = (operation, callback) ->
  transforms = Transforms[operation]
  args = {
    out: operation
  }
  if transforms.f
    args['finalize'] = transforms.f
  @collection.mapReduce(transforms.m, transforms.r, args, callback)

Page = mongoose.model 'Page', PageSchema
module.exports = Page

#db.links.group({key:'value.count', initial:{c:[]},reduce:function(o,p){if(p.c[o.value.count]){p.c[o.value.count]++;}else{p.c[o.value.count]=1}}})
