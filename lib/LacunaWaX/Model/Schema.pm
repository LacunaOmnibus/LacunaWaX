
=pod

The installation process is NOT using ->deploy to generate the databases.  
Instead, the database asset creation statements are hard-coded in 
post_install_script.pl.

So any changes made to this schema must also be made, by hand, to 
post_install_script.pl.


*** NOT NULL ***
If you set a column to not nullable (other than the id), you MUST include a 
default value, or you'll break the ability to import from old databases.

=cut

package LacunaWaX::Model::Schema::AppPrefsKeystore {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('AppPrefsKeystore');
    __PACKAGE__->add_columns( 
        id      => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1}  },
        name    => {data_type => 'varchar', size => 64,             is_nullable => 0, default_value => "unset"  },
        value   => {data_type => 'varchar', size => 64,             is_nullable => 1                            },
    );
    __PACKAGE__->set_primary_key( 'id' ); 

}#}}}
package LacunaWaX::Model::Schema::ArchMinPrefs {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('ArchMinPrefs');
    __PACKAGE__->add_columns( 
        id                  => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        server_id           => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        body_id             => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        glyph_home_id       => {data_type => 'integer',                         is_nullable => 1, extra => {unsigned => 1} },
        reserve_glyphs      => {data_type => 'integer',                         is_nullable => 0, default_value => '0' },
        pusher_ship_name    => {data_type => 'varchar', size => 32,             is_nullable => 1 },
        auto_search_for     => {data_type => 'varchar', size => 32,             is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->add_unique_constraint( 'one_per_body' => [qw(server_id body_id)] ); 

    sub sqlt_deploy_hook {#{{{
        my $self  = shift;
        my $table = shift;
        $table->add_index(name => 'ArchMinPrefs_server_id', fields => ['server_id']);
        $table->add_index(name => 'ArchMinPrefs_body_id',   fields => ['body_id']);
        return 1;
    }#}}}

}#}}}
package LacunaWaX::Model::Schema::BodyTypes {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('BodyTypes');
    __PACKAGE__->add_columns( 
        id              => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1}  },
        body_id         => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1}  },
        server_id       => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1}  },
        type_general    => {data_type => 'varchar', size => 16,             is_nullable => 1                            },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->add_unique_constraint( 'one_per_server' => [qw(body_id server_id)] ); 

    sub sqlt_deploy_hook {#{{{
        my $self  = shift;
        my $table = shift;
        $table->add_index(name => 'BodyTypes_body_id', fields => ['body_id']);
        $table->add_index(name => 'BodyTypes_type_general', fields => ['type_general']);
        return 1;
    }#}}}
    
}#}}}
package LacunaWaX::Model::Schema::LotteryPrefs {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('LotteryPrefs');
    __PACKAGE__->add_columns( 
        id          => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        server_id   => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        body_id     => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        count       => {data_type => 'integer',                         is_nullable => 0, default_value => 1, },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->add_unique_constraint( 'LotteryPrefs_body' => [qw(body_id server_id)] ); 
}#}}}
package LacunaWaX::Model::Schema::Mission {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('Mission');
    __PACKAGE__->add_columns( 
        id              => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        name            => {data_type => 'varchar', size => 32,             is_nullable => 0,  },
        description     => {data_type => 'text',                            is_nullable => 1,  },
        net19_head      => {data_type => 'text',                            is_nullable => 1,  },
        net19_complete  => {data_type => 'text',                            is_nullable => 1,  },
        max_university  => {data_type => 'integer',                         is_nullable => 0, default_value => 30  },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->add_unique_constraint( 'mission_name' => [qw(name)] ); 
    __PACKAGE__->has_many(
        materiel_objective => 'LacunaWaX::Model::Schema::MissionMaterielObjective', 
        { 'foreign.mission_id' => 'self.id' }
    );
    __PACKAGE__->has_many(
        fleet_objective => 'LacunaWaX::Model::Schema::MissionFleetObjective', 
        { 'foreign.mission_id' => 'self.id' }
    );
    __PACKAGE__->has_many(
        reward => 'LacunaWaX::Model::Schema::MissionReward', 
        { 'foreign.mission_id' => 'self.id' }
    );
}#}}}
package LacunaWaX::Model::Schema::MissionFleetObjective {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('MissionFleetObjective');
    __PACKAGE__->add_columns( 
        id                  => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1}  },
        mission_id          => {data_type => 'integer', is_auto_increment => 0, is_nullable => 0, extra => {unsigned => 1}  },
        ship_type           => {data_type => 'varchar', size => 32,             is_nullable => 1,                           },
        ship_quantity       => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        targ_in_zone        => {data_type => 'integer',                         is_nullable => 1,                           },
        ### 'any', or a specific star color
        targ_color          => {data_type => 'varchar', size => 32,             is_nullable => 0, default_value => 'any'    },
        targ_inhabited      => {data_type => 'integer',                         is_nullable => 1,                           },
        targ_isolationist   => {data_type => 'integer',                         is_nullable => 1,                           },
        targ_size_min       => {data_type => 'integer',                         is_nullable => 1,                           },
        targ_size_max       => {data_type => 'integer',                         is_nullable => 1,                           },
        ### 'star', 'habitable', 'gas_giant', 'asteroid'
        targ_type           => {data_type => 'varchar', size => 32,             is_nullable => 0, default_value => 'habitable'  },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->belongs_to(
        mission => 'LacunaWaX::Model::Schema::Mission', 
        { 'foreign.id' => 'self.mission_id' }
    );
}#}}}
package LacunaWaX::Model::Schema::MissionMaterielObjective {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('MissionMaterielObjective');
    __PACKAGE__->add_columns( 
        id          => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        mission_id  => {data_type => 'integer', is_auto_increment => 0, is_nullable => 0, extra => {unsigned => 1} },
        type        => {data_type => 'varchar', size => 32,             is_nullable => 1,  },   # 'resource'
        name        => {data_type => 'varchar', size => 32,             is_nullable => 1,  },   # 'gold'
        quantity    => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        level       => {data_type => 'integer',                         is_nullable => 0, default_value => 1 },
        extra_level => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        ship_name   => {data_type => 'varchar', size => 32,             is_nullable => 1,  },
        berth       => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        cargo       => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        combat      => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        occupants   => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        speed       => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        stealth     => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->belongs_to(
        mission => 'LacunaWaX::Model::Schema::Mission', 
        { 'foreign.id' => 'self.mission_id' }
    );
}#}}}
package LacunaWaX::Model::Schema::MissionReward {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('MissionReward');
    __PACKAGE__->add_columns( 
        id          => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        mission_id  => {data_type => 'integer', is_auto_increment => 0, is_nullable => 0, extra => {unsigned => 1} },
        type        => {data_type => 'varchar', size => 32,             is_nullable => 1,  },   # 'plans'
        name        => {data_type => 'varchar', size => 32,             is_nullable => 1,  },   # 'Junk Pyramid Sculpture'
        quantity    => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        level       => {data_type => 'integer',                         is_nullable => 0, default_value => 1 },
        extra_level => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        ship_name   => {data_type => 'varchar', size => 32,             is_nullable => 1,  },
        berth       => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        cargo       => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        combat      => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        occupants   => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        speed       => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
        stealth     => {data_type => 'integer',                         is_nullable => 0, default_value => 0 },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->belongs_to(
        mission => 'LacunaWaX::Model::Schema::Mission', 
        { 'foreign.id' => 'self.mission_id' }
    );
}#}}}
package LacunaWaX::Model::Schema::ScheduleAutovote {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('ScheduleAutovote');
    __PACKAGE__->add_columns( 
        id              => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        server_id       => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        proposed_by    => {data_type => 'varchar', size => 16, is_nullable => 0, default_value => 'all'}, # 'none', 'owner', or 'all'
    );
    __PACKAGE__->set_primary_key( 'id' ); 

}#}}}
package LacunaWaX::Model::Schema::ServerAccounts {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('ServerAccounts');
    __PACKAGE__->add_columns( 
        id                  => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1}          },
        server_id           => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1}          },
        username            => {data_type => 'varchar', size => 64,             is_nullable => 0, default_value => 'YOUR USERNAME', },
        password            => {data_type => 'varchar', size => 64,             is_nullable => 0, default_value => 'YOUR PASSWORD', },
        default_for_server  => {data_type => 'integer',                         is_nullable => 1, extra => {unsigned => 1}          },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->has_one(
        server => 'LacunaWaX::Model::Schema::Servers', 
        { 'foreign.id' => 'self.server_id' }
    );
    __PACKAGE__->add_unique_constraint( 'ServerAccounts_one_per_server' => [qw(server_id username)] ); 

    sub all_servers {#{{{
        my $self = shift;

=pod

Returns a recordset containing all possible servers.  You could certainly 
just query the schema yourself, but trying to remember the correct spelling of 
"Enum_Servers" is going to be a pain.

=cut

        my $schema   = $self->result_source->schema;
        my $servers_rs = $schema->resultset('Enum_Servers')->search();
        return $servers_rs;
    }#}}}

}#}}}
package LacunaWaX::Model::Schema::Servers {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('Servers');
    __PACKAGE__->add_columns( 
        id          => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1}                  },
        name        => {data_type => 'varchar', size => 32,             is_nullable => 0, default_value => 'US1'                    },
        url         => {data_type => 'varchar', size => 64,             is_nullable => 0, default_value => 'us1.lacunaexpanse.com'  },
        protocol    => {data_type => 'varchar', size =>  8,             is_nullable => 1, default_value => 'http'                   },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->add_unique_constraint( 'unique_by_name' => [qw(name)] ); 
}#}}}
package LacunaWaX::Model::Schema::SitterPasswords {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('SitterPasswords');
    __PACKAGE__->add_columns( 
        id          => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        server_id   => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        player_id   => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        player_name => {data_type => 'varchar', size => 64,             is_nullable => 1 },
        sitter      => {data_type => 'varchar', size => 64,             is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->add_unique_constraint( 'one_player_per_server' => [qw(server_id player_id)] ); 
}#}}}
package LacunaWaX::Model::Schema::SSAlerts {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('SSAlerts');
    __PACKAGE__->add_columns( 
        id              => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        server_id       => {data_type => 'integer',                         is_nullable => 0, },
        station_id      => {data_type => 'integer',                         is_nullable => 0  },
        enabled         => {data_type => 'integer',                         is_nullable => 0, default_value => '0' },
        hostile_ships   => {data_type => 'integer',                         is_nullable => 0, default_value => '0' },
        hostile_spies   => {data_type => 'integer',                         is_nullable => 0, default_value => '0' },
        min_res         => {data_type => 'bigint',                          is_nullable => 0, default_value => '0' },
        own_star_seized => {data_type => 'integer',                         is_nullable => 0, default_value => '0' },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->add_unique_constraint( 'one_alert_per_station' => [qw(server_id station_id)] ); 

    sub sqlt_deploy_hook {#{{{
        my $self  = shift;
        my $table = shift;
        $table->add_index(name => 'SSAlerts_station_id', fields => ['server_id', 'station_id']);
        return 1;
    }#}}}
}#}}}
package LacunaWaX::Model::Schema::SpyTrainPrefs {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('SpyTrainPrefs');
    __PACKAGE__->add_columns( 
        id          => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        server_id   => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        spy_id      => {data_type => 'integer',                         is_nullable => 0, extra => {unsigned => 1} },
        train       => {data_type => 'varchar', size => 32,             is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->add_unique_constraint( 'unique_server_spy' => [qw(server_id spy_id)] ); 

    sub sqlt_deploy_hook {#{{{
        my $self  = shift;
        my $table = shift;
        $table->add_index(name => 'SpyTrainPrefs_spy_id',   fields => ['spy_id']);
        $table->add_index(name => 'SpyTrainPrefs_train',    fields => ['train']);
        return 1;
    }#}}}

}#}}}

package LacunaWaX::Model::Schema::TestTable {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('TestTable');
    __PACKAGE__->add_columns( 
        id   => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        fname => {data_type => 'varchar', size => 32,             is_nullable => 1 },
        lname => {data_type => 'varchar', size => 32,             is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
}#}}}
package LacunaWaX::Model::Schema::TestTableAgain {#{{{
    use v5.14;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('TestTableAgain');
    __PACKAGE__->add_columns( 
        id    => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        fname => {data_type => 'varchar', size => 64,             is_nullable => 1 },
        lname => {data_type => 'varchar', size => 64,             is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
}#}}}

package LacunaWaX::Model::Schema {
    use v5.14;
    use warnings;
    use base qw(DBIx::Class::Schema);

    our $VERSION = '0.1';

    __PACKAGE__->load_classes(qw/
        AppPrefsKeystore
        ArchMinPrefs
        BodyTypes
        LotteryPrefs
        Mission
        MissionFleetObjective
        MissionMaterielObjective
        MissionReward
        ScheduleAutovote
        ServerAccounts
        Servers
        SitterPasswords
        SpyTrainPrefs
        SSAlerts
    /);
    ### Add these to the list above if you want to play around with some test 
    ### tables.
    #    TestTable
    #    TestTableAgain
}

1;
