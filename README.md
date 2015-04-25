# Visualizing google maps trips w/ streetview

[This](http://visualize-google-trip.s3-website-us-west-2.amazonaws.com/) is a quick visualization that takes Google maps directions and turns them into an interactive slideshow. Hopefully it will give you a better sense of where you're going!

![image](https://cloud.githubusercontent.com/assets/1022564/7333056/f1312c08-eb2c-11e4-95f7-602b120a4092.png)

## To download and develop yourself

This site uses [middleman](http://middlemanapp.com/). After running `bundle` to
install required gems, start middleman with:

```bash
$ bundle exec middleman server
```

## Deploy

This site is deployed as a static page to Amazon S3. You can deploy in two steps:

1) Build

```bash
$ STAGE=beta bundle exec middleman build
```

2) Publish

```bash
$ STAGE=beta bundle exec middleman s3_sync
```

NOTE: The `STAGE` is prefixed to build an env file to use. So `beta` will use a
file called `.env-beta`, and `prod` will use a file called `.env-prod`. *You need
to make these files, use `.env-example` as a template. You might also want a local `.env`*
