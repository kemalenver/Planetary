/*
 *  Data.cpp
 *  Kepler
 *
 *  Created by Robert Hodgin on 2/25/11.
 *  Copyright 2013 Smithsonian Institution. All rights reserved.
 *
 */

#include "Data.h"
#include "cinder/Utilities.h" // for toString
#include "TaskQueue.h"        // for backgrounding tasks

using namespace ci;
using namespace ci::ipod;
using namespace std;

void Data::setup()
{
	mArtists.clear();
	mPlaylists.clear();
    mNumArtistsPerChar.clear();

    if (mState != LoadStateLoading) {
        mState = LoadStateLoading;
        mArtistProgress = 0.0f;
        mPlaylistProgress = 0.0f;

        // Run backgroundInit on a background thread to avoid blocking main thread
        // This is critical for iOS permission dialogs to work properly
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            backgroundInit();
        });
    }
}

void Data::backgroundInit()
{
    NSLog(@"Data::backgroundInit() - Starting music library load...");
	mPendingArtists = getArtists( std::bind1st( std::mem_fun(&Data::artistProgress), this ) );
    NSLog(@"Data::backgroundInit() - Loaded %lu artists", (unsigned long)mPendingArtists.size());

    mPendingPlaylists = getPlaylists( std::bind1st( std::mem_fun(&Data::playlistProgress), this ) );
    NSLog(@"Data::backgroundInit() - Loaded %lu playlists", (unsigned long)mPendingPlaylists.size());
	
// QUICK FIX FOR GETTING MORE DATA ONTO THE ALPHAWHEEL
    
	string alphaString	= "ABCDEFGHIJKLMNOPQRSTUVWXYZ#";
	for( int i=0; i<27; i++ ){
		mNumArtistsPerChar[alphaString[i]] = 0;
	}
	float maxCount = 0.0001f;
	for( vector<ci::ipod::PlaylistRef>::iterator it = mPendingArtists.begin(); it != mPendingArtists.end(); ++it ){
        
		string name		= (*it)->getArtistName();
		string the		= name.substr( 0, 4 );
		char firstLetter;
		
		if( the == "The " || the == "the " ){
			firstLetter = name[4];
		} else {
			firstLetter = name[0];
		}
		
		if( isdigit(firstLetter) ){
			firstLetter = '#';
		} else {
			firstLetter = static_cast<char> ( toupper( firstLetter ) );
		}
		
		mNumArtistsPerChar[firstLetter] += 1.0f;
		
		if( mNumArtistsPerChar[firstLetter] > maxCount ){
			maxCount = mNumArtistsPerChar[firstLetter];
		}
	}
	
	for( int i=0; i<27; i++ ){
		mNormalizedArtistsPerChar[i] = mNumArtistsPerChar[alphaString[i]]/maxCount;
	}

// END ALPHAWHEEL QUICK FIX
	    
    mState = LoadStatePending;
}


void Data::update()
{
	if (mState == LoadStatePending) {

		mArtists.insert( mArtists.end(), mPendingArtists.begin(), mPendingArtists.end() );
		mPendingArtists.clear();
		
		mPlaylists.insert( mPlaylists.end(), mPendingPlaylists.begin(), mPendingPlaylists.end() );
		mPendingPlaylists.clear();
		        
        mState = LoadStateComplete;
	}
}
