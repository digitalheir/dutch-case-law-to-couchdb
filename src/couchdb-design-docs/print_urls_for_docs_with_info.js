var oboe = require('oboe');

var url = 'https://rechtspraak.cloudant.com/docs/_design/stats/_view/richness_of_markup?stale=ok&reduce=false&endkey=[[1]]';
oboe(url)
    .node('!.rows.*', function (row) {

        // This callback will be called everytime a new object is
        // found in the foods array.

        console.log('https://rechtspraak.lawreader.nl/ecli/'+row.id);
        return oboe.drop;
    })
    .done(function (things) {

        console.log(
            'there are', things.foods.length, 'things to eat',
            'and', things.nonFoods.length, 'to avoid');
    });