'use strict'

module.exports = {
  async up(knex) {
    await knex.schema.createTableIfNotExists('post_summaries', (table) => {
        table.increments('id').primary()
        table.integer('post_id')
          .unsigned()
          .notNullable()
          .unique() // enforces one-to-one
          .references('id')
          .inTable('temple_posts')
          .onDelete('CASCADE')
        table.text('summary')
        table.timestamps(true, true) // created_at, updated_at
    });
  },

  async down(knex) {
    await knex.schema.dropTableIfExists('post_summaries');
  }
}